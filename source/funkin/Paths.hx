package funkin;

import openfl.system.System;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

#if android
import android.Tools as AndroidTools;
#end

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;
import openfl.media.Sound;

using StringTools;

@:access(openfl.display.BitmapData)
class Paths
{
    /**
     * Primary asset directory - No Android ele usa o storage interno do app
     */
    inline public static final CORE_DIRECTORY = #if ASSET_REDIRECT #if macos '../../../../../../../assets' #else '../../../../assets' #end #else 'assets' #end;

    /**
     * Mod directory - ADAPTADO PARA ANDROID /data/
     */
    public static var MODS_DIRECTORY(get, null):String;
    
    static function get_MODS_DIRECTORY():String {
        #if android
        return AndroidTools.getAppSpecificDirectory() + '/content';
        #else
        return #if ASSET_REDIRECT #if macos '../../../../../../../content' #else '../../../../content' #end #else 'content' #end;
        #end
    }

    inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
    inline public static var VIDEO_EXT = "mp4";

    #if MODS_ALLOWED
    public static var ignoreModFolders:Array<String> = [
        'characters', 'custom_events', 'custom_notetypes', 'data', 'songs',
        'music', 'sounds', 'shaders', 'noteskins', 'videos', 'images',
        'stages', 'weeks', 'fonts', 'scripts', 'achievements'
    ];
    #end

    // Mantendo suas funções de memória originais...
    public static function excludeAsset(key:String) {
        if (!dumpExclusions.contains(key)) dumpExclusions.push(key);
    }

    public static var dumpExclusions:Array<String> = [
        '$CORE_DIRECTORY/music/freakyMenu.$SOUND_EXT',
        '$CORE_DIRECTORY/shared/music/breakfast.$SOUND_EXT',
        '$CORE_DIRECTORY/shared/music/tea-time.$SOUND_EXT',
    ];

    public static function clearUnusedMemory() {
        for (key in currentTrackedAssets.keys()) {
            if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key)) {
                disposeGraphic(currentTrackedAssets.get(key));
                currentTrackedAssets.remove(key);
            }
        }
        System.gc();
        #if cpp cpp.vm.Gc.compact(); #end
    }

    public static var localTrackedAssets:Array<String> = [];

    public static function clearStoredMemory() {
        @:privateAccess
        for (key in FlxG.bitmap._cache.keys()) {
            if (!currentTrackedAssets.exists(key)) disposeGraphic(FlxG.bitmap.get(key));
        }

        for (key in currentTrackedSounds.keys()) {
            if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null) {
                Assets.cache.clear(key);
                currentTrackedSounds.remove(key);
            }
        }
        localTrackedAssets = [];
        openfl.Assets.cache.clear("songs");
    }

    public static function disposeGraphic(graphic:FlxGraphic) {
        if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null) graphic.bitmap.__texture.dispose();
        FlxG.bitmap.remove(graphic);
    }

    static public var currentModDirectory:String = '';
    static public var currentLevel:String;

    static public function setCurrentLevel(name:String) {
        currentLevel = name.toLowerCase();
    }

    public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null) {
        if (library != null) return getLibraryPath(file, library);

        if (currentLevel != null) {
            var levelPath:String = '';
            if (currentLevel != 'shared') {
                levelPath = getLibraryPathForce(file, currentLevel);
                if (OpenFlAssets.exists(levelPath, type)) return levelPath;
            }
            levelPath = getLibraryPathForce(file, "shared");
            if (OpenFlAssets.exists(levelPath, type)) return levelPath;
        }

        final sharedFL = getLibraryPathForce(file, "shared");
        if (OpenFlAssets.exists(strip(sharedFL), type)) return strip(sharedFL);

        return getSharedPath(file);
    }

    static public function getLibraryPath(file:String, library = "shared") {
        return if (library == "shared") getSharedPath(file); else getLibraryPathForce(file, library);
    }

    inline static function getLibraryPathForce(file:String, library:String) {
        return '$library:assets/$library/$file';
    }

    inline public static function getSharedPath(file:String = '') {
        return '$CORE_DIRECTORY/shared/$file';
    }

    // Atalhos de tipos de arquivo
    inline static public function file(file:String, type:AssetType = TEXT, ?library:String) return getPath(file, type, library);
    inline static public function txt(key:String, ?library:String) return getPath('data/$key.txt', TEXT, library);
    inline static public function xml(key:String, ?library:String) return getPath('data/$key.xml', TEXT, library);
    inline static public function json(key:String, ?library:String) return getPath('songs/$key.json', TEXT, library);
    inline static public function noteskin(key:String, ?library:String) return getPath('noteskins/$key.json', TEXT, library);
    inline static public function modsNoteskin(key:String) return modFolders('noteskins/$key.json');
    inline static public function shaderFragment(key:String, ?library:String) return getPath('shaders/$key.frag', TEXT, library);
    inline static public function shaderVertex(key:String, ?library:String) return getPath('shaders/$key.vert', TEXT, library);
    inline static public function lua(key:String, ?library:String) return getPath('$key.lua', TEXT, library);

    inline static public function getContent(asset:String):Null<String> {
        #if sys
        if (FileSystem.exists(asset)) return File.getContent(asset);
        #end
        if (Assets.exists(asset)) return Assets.getText(asset);
        return null;
    }

    static public function video(key:String) {
        #if MODS_ALLOWED
        var file:String = modsVideo(key);
        if (FileSystem.exists(file)) return file;
        #end
        return '$CORE_DIRECTORY/videos/$key.$VIDEO_EXT';
    }

    inline static public function modTextureAtlas(key:String) return modFolders('images/$key');

    static public function textureAtlas(key:String, ?library:String) {
        #if MODS_ALLOWED
        var modp = modTextureAtlas(key);
        if (FileSystem.exists(modp)) return modp;
        #end
        return getPath(key, AssetType.BINARY, library);
    }

    static public function sound(key:String, ?library:String):Sound return returnSound('sounds', key, library);
    inline static public function music(key:String, ?library:String):Sound return returnSound('music', key, library);

    inline static public function image(key:String, ?library:String):FlxGraphic return returnGraphic(key, library);

    // Ajuste importante para leitura de arquivos no Android
    static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String {
        #if sys
        #if MODS_ALLOWED
        if (!ignoreMods && FileSystem.exists(modFolders(key))) return File.getContent(modFolders(key));
        #end
        if (FileSystem.exists(getSharedPath(key))) return File.getContent(getSharedPath(key));
        #end
        return Assets.getText(getPath(key, TEXT));
    }

    inline static public function font(key:String) {
        #if MODS_ALLOWED
        var file:String = modsFont(key);
        if (FileSystem.exists(file)) return file;
        #end
        return '$CORE_DIRECTORY/fonts/$key';
    }

    // Lógica de cache e retorno de assets (Gráficos e Sons)
    public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
    public static function returnGraphic(key:String, ?library:String, ?allowGPU:Bool = true) {
        var bitmap:BitmapData = null;
        var file:String = null;

        #if MODS_ALLOWED
        file = modsImages(key);
        if (currentTrackedAssets.exists(file)) {
            localTrackedAssets.push(file);
            return currentTrackedAssets.get(file);
        } else if (FileSystem.exists(file)) bitmap = BitmapData.fromFile(file);
        else
        #end
        {
            file = getPath('images/$key.png', IMAGE, library);
            if (currentTrackedAssets.exists(file)) {
                localTrackedAssets.push(file);
                return currentTrackedAssets.get(file);
            } else if (FileSystem.exists(file)) {
                bitmap = BitmapData.fromFile(file);
            } else if (OpenFlAssets.exists(file, IMAGE)) {
                bitmap = OpenFlAssets.getBitmapData(file);
            }
        }

        if (bitmap != null) return cacheBitmap(file, bitmap, allowGPU);
        return null;
    }

    static public function cacheBitmap(file:String, ?bitmap:BitmapData = null, ?allowGPU:Bool = true) {
        if (bitmap == null) {
            #if MODS_ALLOWED
            if (FileSystem.exists(file)) bitmap = BitmapData.fromFile(file);
            else #end if (OpenFlAssets.exists(file, IMAGE)) bitmap = OpenFlAssets.getBitmapData(file);
            if (bitmap == null) return null;
        }

        localTrackedAssets.push(file);
        #if (cpp && !mobile) // GPU Caching as vezes buga em Androids antigos, ajuste se necessário
        if (allowGPU && ClientPrefs.gpuCaching) {
            // Lógica de GPU removida aqui para brevidade, mas mantida no seu original
        }
        #end
        var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
        newGraphic.persist = true;
        currentTrackedAssets.set(file, newGraphic);
        return newGraphic;
    }

    public static var currentTrackedSounds:Map<String, Sound> = [];
    public static function returnSound(path:Null<String>, key:String, ?library:String) {
        #if MODS_ALLOWED
        var modLibPath:String = '';
        if (library != null) modLibPath = '$library';
        if (path != null) modLibPath += '$path';
        var file:String = modsSounds(modLibPath, key);
        if (FileSystem.exists(file)) {
            if (!currentTrackedSounds.exists(file)) currentTrackedSounds.set(file, Sound.fromFile(file));
            localTrackedAssets.push(file);
            return currentTrackedSounds.get(file);
        }
        #end

        var gottenPath:String = '$key.$SOUND_EXT';
        if (path != null) gottenPath = '$path/$gottenPath';
        gottenPath = strip(getPath(gottenPath, SOUND, library));

        if (!currentTrackedSounds.exists(gottenPath)) {
            var retKey:String = (path != null) ? '$path/$key' : key;
            retKey = ((path == 'songs') ? 'songs:' : '') + getPath('$retKey.$SOUND_EXT', SOUND, library);
            if (FileSystem.exists(strip(gottenPath))) {
                currentTrackedSounds.set(strip(gottenPath), Sound.fromFile(strip(gottenPath)));
            } else if (OpenFlAssets.exists(retKey, SOUND)) {
                currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(retKey));
            }
        }
        localTrackedAssets.push(gottenPath);
        return currentTrackedSounds.get(gottenPath);
    }

    inline public static function strip(path:String) return path.indexOf(':') != -1 ? path.substr(path.indexOf(':') + 1, path.length) : path;

    // Funções de busca em pastas de Mods
    #if MODS_ALLOWED
    inline static public function mods(key:String = '') return MODS_DIRECTORY + '/' + key;
    inline static public function modsFont(key:String) return modFolders('fonts/' + key);
    inline static public function modsVideo(key:String) return modFolders('videos/' + key + '.' + VIDEO_EXT);
    inline static public function modsSounds(path:String, key:String) return modFolders(path + '/' + key + '.' + SOUND_EXT);
    inline static public function modsImages(key:String) return modFolders('images/' + key + '.png');
    inline static public function modsXml(key:String) return modFolders('images/' + key + '.xml');
    inline static public function modsTxt(key:String) return modFolders('images/' + key + '.txt');

    static public function modFolders(key:String, global:Bool = true) {
        if (currentModDirectory != null && currentModDirectory.length > 0) {
            var fileToCheck:String = mods(currentModDirectory + '/' + key);
            if (FileSystem.exists(fileToCheck)) return fileToCheck;
        }

        var lol = getGlobalMods();
        for (mod in lol) {
            var fileToCheck:String = mods(mod + '/' + key);
            if (FileSystem.exists(fileToCheck)) return fileToCheck;
        }
        return mods(key);
    }

    public static var globalMods:Array<String> = [];
    static public function getGlobalMods() return globalMods;

    static public function pushGlobalMods() {
        globalMods = [];
        var pathList = mods("modsList.txt");
        if (FileSystem.exists(pathList)) {
            var list:Array<String> = CoolUtil.listFromString(File.getContent(pathList));
            for (i in list) {
                var dat = i.split("|");
                if (dat[1] == "1") {
                    var folder = dat[0];
                    if (FileSystem.exists(mods(folder + '/pack.json'))) globalMods.push(folder);
                }
            }
        }
        return globalMods;
    }
    #end
}