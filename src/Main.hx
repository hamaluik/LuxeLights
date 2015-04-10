import luxe.Color;
import luxe.Input;
import luxe.Log;
import luxe.Rectangle;
import luxe.Sprite;
import luxe.Vector;
import phoenix.Batcher;
import phoenix.RenderTexture;
import phoenix.Texture;
import luxe.Parcel;
import phoenix.Shader;

class Main extends luxe.Game {
	// use a render texture for the "lightmap"
	var lightRenderTexture:RenderTexture;
	// it also needs it's own geometry batcher
	var lightBatcher:Batcher;

	// set the ambient colour to a deep blue for a nice nighttime effect
	var ambientColor:Vector = new Vector(0.3, 0.3, 0.7, 0.7);

	// sprite that will get rendered into the lightmap rendertexture
	var lightSprite:Sprite;
	var campfireLight:Sprite;
	var occluderSprite:Sprite;

	// a shader that all lit entities must use
	var lightShader:Shader;

	// the main background level
	var levelSprite:Sprite;

	// three types of occlusion textures to play with
	var occlusionTexture_solid:Texture;
	var occlusionTexture_rims:Texture;
	var occlusionTexture_gradient:Texture;

	// a timer to make the fire light flicker nicely
	var fireUpdateNextTime:Float = 0;

	override function ready() {
		// load the parcel
		Luxe.loadJSON("assets/parcel.json", function(jsonParcel) {
			var parcel = new Parcel();
			parcel.from_json(jsonParcel.json);

			// show a loading bar
			// use a fancy custom loading bar (https://github.com/FuzzyWuzzie/CustomLuxePreloader)
			new DigitalCircleParcelProgress({
				parcel: parcel,
				oncomplete: assetsLoaded
			});
			
			// start loading!
			parcel.load();
		});
	} //ready

	function assetsLoaded(_) {
		// create a level sprite to display in the background
		levelSprite = new Sprite({
			texture: Luxe.resources.find_texture('assets/level.png'),
			pos: Luxe.screen.mid,
			size: new Vector(960, 640),
			depth: 0
		});
		levelSprite.texture.filter = phoenix.Texture.FilterType.nearest;

		// --- NOW LIGHTS ---

		// create a render texture for the lights
		lightRenderTexture = new RenderTexture(Luxe.resources, new Vector(1024, 1024));

		// and a batcher for all the lights
		lightBatcher = Luxe.renderer.create_batcher({
			name: 'lights_batcher',
			no_add: true
		});
		// set the batcher's viewport to be the same as the main camera
		lightBatcher.view.viewport = Luxe.camera.viewport;

		// create the light sprite which will render to the lightRenderTexture
		lightSprite = new Sprite({
			texture: Luxe.resources.find_texture('assets/light.png'),
			pos: Luxe.screen.mid,
			size: new Vector(128, 128),
			batcher: lightBatcher,
			color: new Color().rgb(0xffe786)
		});
		lightSprite.texture.filter = phoenix.Texture.FilterType.nearest;

		// create the campfire light in the same way as the mouse light
		campfireLight = new Sprite({
			texture: Luxe.resources.find_texture('assets/light.png'),
			pos:Luxe.screen.mid,
			size: new Vector(256, 256),
			batcher: lightBatcher,
			color: new Color().rgb(0xff4d07)
		});

		// load the various occlusion textures
		occlusionTexture_solid = Luxe.resources.find_texture('assets/occlusion_solid.png');
		occlusionTexture_rims = Luxe.resources.find_texture('assets/occlusion_rims.png');
		occlusionTexture_gradient = Luxe.resources.find_texture('assets/occlusion_gradient.png');

		// make em nice and pixely
		occlusionTexture_solid.filter = phoenix.Texture.FilterType.nearest;
		occlusionTexture_rims.filter = phoenix.Texture.FilterType.nearest;
		occlusionTexture_gradient.filter = phoenix.Texture.FilterType.nearest;

		// create the occluder
		occluderSprite = new Sprite({
			texture: occlusionTexture_solid,
			pos: Luxe.screen.mid,
			size: new Vector(960, 640),
			depth: 997,
			batcher: lightBatcher
		});

		// setup the light shader
		lightShader = Luxe.resources.find_shader('assets/light.glsl|default');
		levelSprite.shader = lightShader;

		// set the ambient colour
		lightShader.set_vector4('ambientColor', ambientColor);

		// and the resolution (for lightmap texture lookup)
		lightShader.set_vector2('resolution', new Vector(1024, 1024));

		// move to the second slot
		lightRenderTexture.slot = 1;
		lightShader.set_texture('lightMap', lightRenderTexture);
	}

	override function onkeyup( e:KeyEvent ) {

		if(e.keycode == Key.escape) {
			Luxe.shutdown();
		}
		// use the up and down keys to control the ambient light strength
		else if(e.keycode == Key.up) {
			ambientColor.w = Math.min(ambientColor.w + 0.1, 1);
			if(lightShader != null) {
				lightShader.set_vector4('ambientColor', ambientColor);
			}
		}
		else if(e.keycode == Key.down) {
			ambientColor.w = Math.max(ambientColor.w - 0.1, 0);
			if(lightShader != null) {
				lightShader.set_vector4('ambientColor', ambientColor);
			}
		}
		// set the different occlusion textures
		else if(e.keycode == Key.key_1) {
			occluderSprite.texture = occlusionTexture_solid;
		}
		else if(e.keycode == Key.key_2) {
			occluderSprite.texture = occlusionTexture_rims;
		}
		else if(e.keycode == Key.key_3) {
			occluderSprite.texture = occlusionTexture_gradient;
		}

	} //onkeyup

	override public function onmousemove(event:MouseEvent) {
		if(lightSprite != null) {
			// make the lightSprite follow the cursor
			lightSprite.pos.x = event.pos.x;
			lightSprite.pos.y = event.pos.y;
		}
	}
	// use the pre-render function to render to render textures
	override function onprerender() {
		// wait for the batcher to be up and running
		if(lightBatcher == null) {
			return;
		}

		// switch the render texture to the lights texture
		Luxe.renderer.target = lightRenderTexture;

		// clear it
		Luxe.renderer.clear(new Color(0, 0, 0, 0));

		// draw all the lights using the batcher
		lightBatcher.draw();

		// unset the render target
		// so that we go back to rendering to the screen
		Luxe.renderer.target = null;
	}

	override function update(dt:Float) {
		// flicker the campfire
		fireUpdateNextTime -= dt;
		if(campfireLight != null && fireUpdateNextTime <= 0) {
			campfireLight.scale = new Vector((Math.random() - 0.5) * 0.1 + 1, (Math.random() - 0.5) * 0.1 + 1);
			fireUpdateNextTime = Math.random() * 0.1;
		}
	} //update


} //Main
