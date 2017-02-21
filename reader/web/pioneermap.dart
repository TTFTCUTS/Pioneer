part of Pioneer;

class PioneerMap {
	MapInfo mapInfo;
	BiomeInfo biomeInfo;

	List<MapTile> tiles = [];

	int xpos = 0;
	int zpos = 0;

	PioneerMap(Archive archive) {
		ArchiveFile mapinfofile = archive.findFile("map.json");
		ArchiveFile biomeinfofile = archive.findFile("biomes.json");

		var mapinfo = JSON.decode(UTF8.decode(mapinfofile.content));
		var biomeinfo = JSON.decode(UTF8.decode(biomeinfofile.content));

		this.mapInfo = new MapInfo(mapinfo);
		this.biomeInfo = new BiomeInfo(biomeinfo);

		int n = this.mapInfo.tileRange;

		for (int x = 0; x<n; x++) {
			for (int z = 0; z<n; z++) {
				ArchiveFile f = archive.findFile("tiles/${x}_${z}.png");

				Image image = decodePng(f.content);

				MapTile tile = new MapTile(image.getBytes(), x,z);
				this.tiles.add(tile);
				tile.draw(canvas, MapTile.TILESIZE * x, MapTile.TILESIZE * z, this.biomeInfo);
			}
		}
	}

	void destroy() {

	}

	void mouseOver(MouseEvent e) {
		int x = (e.offset.x - mapInfo.mapOffsetX ) * mapInfo.skip + mapInfo.offsetX;
		int z = (e.offset.y - mapInfo.mapOffsetZ ) * mapInfo.skip + mapInfo.offsetZ;

		querySelector("#output").innerHtml= "$x, $z";
	}
}

class MapInfo {
	String name;
	int dimension;
	String dimensionType;
	String seed;
	String generatorName;
	String generatorVersion;
	String generatorOptions;
	int offsetX = 0;
	int offsetZ = 0;
	int radius = 0;
	int skip = 1;
	int jobSize = 0;
	int tileRange = 0;
	int mapOffsetX;
	int mapOffsetZ;

	MapInfo(dynamic mapjson) {
		this.name = mapjson["worldname"];
		this.dimension = mapjson["dimension"];
		this.dimensionType = mapjson["dimensiontype"];
		this.seed = mapjson["seed"];
		this.generatorName = mapjson["generator"]["name"];
		this.generatorVersion = mapjson["generator"]["version"];
		this.generatorOptions = mapjson["generator"]["options"];
		this.offsetX = mapjson["x"];
		this.offsetZ = mapjson["z"];
		this.radius = mapjson["radius"];
		this.skip = mapjson["skip"];
		this.jobSize = mapjson["jobsize"];
		this.tileRange = mapjson["tilerange"];

		print("$name (dim $dimension, $dimensionType, $generatorName v$generatorVersion), seed: $seed");
		print("$jobSize tiles, $tileRange x $tileRange (radius $radius, scale $skip)");
		print("origin offset: $offsetX,$offsetZ");

		this.mapOffsetX = (((MapTile.TILESIZE * tileRange) )~/2);
		this.mapOffsetZ = (((MapTile.TILESIZE * tileRange) )~/2);
	}
}

class BiomeInfo {
	Map<int, Biome> biomes = new HashMap<int, Biome>();
	Map<String, Biome> biomesByName = new HashMap<String, Biome>();

	BiomeInfo(Map biomejson) {

		for (String key in biomejson.keys) {
			int id = int.parse(key, onError: (String s) => -1);
			if (id == -1) {continue;}

			var data = biomejson[key];
			Biome b = new Biome(id, data);
			biomes[id] = b;
			biomesByName[b.name] = b;
		}
	}
}

class Biome {
	int id;
	String name;

	String colour;
	int red = 127;
	int green = 127;
	int blue = 127;

	double baseHeight;
	double heightVariation;
	double temperature;
	double moisture;
	bool snowy;
	bool canRain;

	bool mutation = false;
	int mutationOf = -1;

	Biome(int this.id, Map biomedata) {
		this.name = biomedata["name"];
		this.colour = biomedata["colour"];
		this.baseHeight = biomedata["height"];
		this.heightVariation = biomedata["heightvariation"];
		this.temperature = biomedata["temperature"];
		this.moisture = biomedata["moisture"];
		this.snowy = biomedata["snow"];
		this.canRain = biomedata["rain"];

		this.mutation = biomedata["mutation"];
		if (this.mutation) {
			this.mutationOf = biomedata["mutationof"];
		}

		this.parseColour();

		//print("$id - $name: temp: $temperature, moisture: $moisture, height: $baseHeight~$heightVariation, rain: $canRain, snow: $snowy");
	}

	void parseColour() {
		int col = int.parse(this.colour.substring(1), radix:16, onError:(s)=>-1);
		if (col == -1) {
			return;
		}

		this.red = (col & 0xFF0000) >> 16;
		this.green = (col & 0x00FF00) >> 8;
		this.blue = (col & 0x0000FF);

		//print("$name: $colour -> $col: $red,$green,$blue");
		//print("red: ${col & 0xFF0000} >> 16 = ${(col & 0xFF0000) >> 16}");
	}
}

class MapTile {
	static const int TILESIZE = 128;

	int tilex;
	int tilez;
	Uint8List data;

	MapTile(Uint8List this.data, int this.tilex, int this.tilez) {

	}

	void draw(CanvasRenderingContext2D canvas, int ox, int oz, BiomeInfo biomes) {
		ImageData img = canvas.getImageData(ox,oz,TILESIZE,TILESIZE);

		//print("############################");
		for (int x=0; x<TILESIZE; x++) {
			for (int z=0; z<TILESIZE; z++) {
				int index = (z*TILESIZE+x)*4;

				int id = this.data[index];
				Biome b = biomes.biomes[id];

				//print("[$tilex,$tilez]: $index $x,$z: $id");// - ${b.name}");

				img.data[index] = b.red;
				img.data[index+1] = b.green;
				img.data[index+2] = b.blue;
				img.data[index+3] = 255;
			}
		}

		canvas.putImageData(img, ox,oz);
	}
}