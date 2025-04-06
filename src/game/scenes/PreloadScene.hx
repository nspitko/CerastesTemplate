package game.scenes;

import cerastes.SoundManager;
import cerastes.EntityBuilder;
import cerastes.Entity.EntityManager;
#if hlimgui
import cerastes.tools.ImguiTool.ImGuiToolManager;
import cerastes.tools.VariableEditor;
#end
import cerastes.flow.Flow.FlowRunner;
import cerastes.ui.Console.GlobalConsole;
import cerastes.Utils;
import cerastes.pass.DitherFX;
import h3d.mat.Texture;
import h2d.Bitmap;
import h2d.RenderContext;
import h3d.scene.*;
import cerastes.shaders.DitherShader;
import cerastes.butai.ButaiNodeManager;
#if butai
import db.Butai;
#end
import cerastes.LocalizationManager;
import hxd.fmt.pak.FileSystem;
import hxd.fs.BytesFileSystem.BytesFileEntry;

@:keep
class PreloadScene extends cerastes.Scene
{
	var fui : h2d.Flow;

	var ready = false;

	function loadAssets()
	{
		#if js
		var fileLoader = new hxd.net.BinaryLoader("res.pak");
		fileLoader.onLoaded = function(bytes:haxe.io.Bytes)
		{
			trace(bytes.length);
			var fileInput = new FileInput( bytes );
			var fs = new hxd.fmt.pak.FileSystem();
			fs.addPak(fileInput);

			hxd.Res.loader = new hxd.res.Loader(fs);

			onReady();
		};

		var loadingBar = new h2d.Bitmap( h2d.Tile.fromColor(0xFFFFFFFF ), s2d );

		s2d.scaleMode = Stretch(1280, 720);

		loadingBar.height = 50;
		loadingBar.x = 0;
		loadingBar.y = 720/2 - loadingBar.height/2;


		fileLoader.onProgress = function(cur, max)
		{
			loadingBar.width = ( cur / max ) * 1280;
		};

		fileLoader.load();

	/*
		var loader:hxd.res.ManifestLoader = hxd.fs.ManifestBuilder.initManifest();
		loader.onLoaded = () -> { trace("All loaded!"); onLoaded(); }
		loader.onFileLoadStarted = (f) -> trace("Started loading file: " + f.path);
		loader.onFileLoaded = (f) -> trace("Finished loading file: " + f.path);
		// This only happens when you use JS target, since sys target is synchronous.
		loader.onFileProgress = (f, loaded, total) -> trace("Loading file progress: " + f.path + ", " + loaded + "/" + total);
		loader.loadManifestFiles();*/
		#else


		#if wwise
		wwise.Api.init("audio", true);
		#end

		onReady();

		#end
	}

	function onReady()
	{
		Utils.info("init console");
		GlobalConsole.init();

		GameState.setup();
		GameState.reset();

		EntityBuilder.init(["data/entites.def"]);

		var language = "en";
		LocalizationManager.initialize(language);
		for( f in GameState.config.localizationFiles )
		{
			LocalizationManager.loadFile('data/${f}_${language}.loc', "common");
		}
		Utils.info("Localization initialized");

		#if flow
		GameState.flow = hxd.Res.data.launch.toFlow();
		#end

		#if wwise
		// @todo we can load these async!!
		for( bank in GameState.config.wwiseBanks )
		{
			Utils.info('Loading audio bank ${bank}');
			wwise.Api.loadBank( bank );
		}
		#end


		#if flow
		GameState.flow.run();
		#else
		switchToNewScene( "game.scenes.TestScene" );
		#end

		SoundManager.musicVol = 0.5;
		SoundManager.playMusicFile("audio/explore.ogg");

	}

	override function tick( delta:Float )
	{
		super.tick( delta );

		if( ready )
			onReady();


	}


	override function preload()
	{
		loadAssets();

		super.preload();
	}





}


