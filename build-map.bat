
@rem to use this batch file, drop a .map file on it or run it from a dos window:
@rem > compile <mapname>

@set Q3MAP_PATH="tools/q3map2.exe"
@set MAP_PATH="res/maps/%1.map"
@set GEN_OPTIONS=""


@rem
%Q3MAP_PATH% -meta -mv 1024 -mi 6144  %GEN_OPTIONS% -v %MAP_PATH%

@rem
%Q3MAP_PATH% -vis -saveprt %GEN_OPTIONS% %MAP_PATH%

@rem
%Q3MAP_PATH% -light -keeplights -fast -samples 2 -filter -patchshadows -external -lightmapsize 256 -approx 8 %GEN_OPTIONS% -v %MAP_PATH%