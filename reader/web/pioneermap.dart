part of Pioneer;

class PioneerMap {
	static const int BORDER = 20;

	MapInfo mapInfo;
	BiomeInfo biomeInfo;

	List<MapTile> tiles;

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

		this.tiles = new List<MapTile>(n*n);

		for (int x = 0; x<n; x++) {
			for (int z = 0; z<n; z++) {
				ArchiveFile f = archive.findFile("tiles/${x}_${z}.png");

				Image image = decodePng(f.content);

				MapTile tile = new MapTile(image.getBytes(), x,z);
				this.tiles[z * n + x] = tile;
			}
		}
	}

	void destroy() {

	}

	void mouseOver(MouseEvent e) {
		int wx = (e.offset.x - mapInfo.mapOffsetX - xpos) * mapInfo.skip + mapInfo.offsetX;
		int wz = (e.offset.y - mapInfo.mapOffsetZ - zpos) * mapInfo.skip + mapInfo.offsetZ;

		Biome b = this.getBiome(e.offset.x,e.offset.y);

		String info = "$wx, $wz";

		if (b != null) {
			info += " ${b.name}";
		}

		querySelector("#output").innerHtml= info;
	}

	draw() {
		this.moveTo(this.xpos, this.zpos);
		int n = this.mapInfo.tileRange;

		int size = n * MapTile.TILESIZE;
		int wwidth = canvasElement.width;
		int wheight = canvasElement.height;

		int xlower = max(0, ((-xpos) / MapTile.TILESIZE).floor());
		int xupper = min(n, ((wwidth - xpos) / MapTile.TILESIZE).ceil());

		int zlower = max(0, ((-zpos) / MapTile.TILESIZE).floor());
		int zupper = min(n, ((wheight - zpos) / MapTile.TILESIZE).ceil());

		//int t = 0;
		for (int x = xlower; x<xupper; x++) {
			for (int z = zlower; z<zupper; z++) {
				int id = z * this.mapInfo.tileRange + x;

				tiles[id].draw(canvas, MapTile.TILESIZE * x + this.xpos, MapTile.TILESIZE * z + this.zpos, this.biomeInfo);
				//t++;
			}
		}
		//print("tiles drawn: $t");
	}

	void moveTo(int x, int z) {
		//print("move to $x,$z");

		int size = this.mapInfo.tileRange * MapTile.TILESIZE;
		int wwidth = canvasElement.width;
		int wheight = canvasElement.height;

		// x position;
		if (wwidth >= size + BORDER * 2) {
			this.xpos = (wwidth - size) ~/ 2;
		} else {
			int maxx = BORDER;
			int minx = wwidth - (BORDER + size);

			this.xpos = x.clamp(minx, maxx);
		}

		// z position;
		if (wheight >= size + BORDER * 2) {
			this.zpos = (wheight - size) ~/ 2;
		} else {
			int maxz = BORDER;
			int minz = wheight - (BORDER + size);

			this.zpos = z.clamp(minz, maxz);
		}
	}

	Point<int> getTileCoords(int x, int z) {
		int tx = (x - this.xpos) ~/ MapTile.TILESIZE;
		int tz = (z - this.zpos) ~/ MapTile.TILESIZE;

		return new Point<int>(tx,tz);
	}

	MapTile getTile(int tileX, int tileZ) {
		int size = this.mapInfo.tileRange;

		if (tileX >= 0 && tileX < size && tileZ >= 0 && tileZ < size ) {
			return this.tiles[tileZ*size + tileX];
		}

		return null;
	}

	Biome getBiome(int x, int z) {
		Point<int> c = this.getTileCoords(x,z);

		MapTile tile = this.getTile(c.x, c.y);

		if (tile == null) {
			return null;
		}

		int tx = x - this.xpos - c.x * MapTile.TILESIZE;
		int tz = z - this.zpos - c.y * MapTile.TILESIZE;

		return tile.getBiome(tx,tz, this.biomeInfo);
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
			Biome b = new Biome(id, data, this);
			biomes[id] = b;
			biomesByName[b.name] = b;
		}
	}
}

class Biome {
	static const double BRIGHTEN = 2.0;

	int id;
	String name;
	BiomeInfo parent;

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

	Biome(int this.id, Map biomedata, BiomeInfo this.parent) {
		this.name = biomedata["name"];
		this.colour = biomedata["colour"];
		this.baseHeight = biomedata["height"];
		this.heightVariation = biomedata["heightvariation"];
		this.temperature = biomedata["temperature"];
		this.moisture = biomedata["moisture"];
		this.snowy = biomedata["snow"];
		this.canRain = biomedata["rain"];

		this.mutation = biomedata["ismutation"];
		if (this.mutation) {
			this.mutationOf = biomedata["mutationof"];
		}

		this.parseColour();

		print("$id - $name: temp: $temperature, moisture: $moisture, height: $baseHeight~$heightVariation, rain: $canRain, snow: $snowy");
		print("Mutation: $mutation , of $mutationOf");
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

	List<int> fillColour(int x, int z) {
		if (this.mutation) {
			if ((x+z) % 5 == 0) { //((x+z)~/2) %2 == 0
				Biome mof = this.parent.biomes[this.mutationOf];

				int r = 255 - mof.red;//(mof.red * BRIGHTEN).clamp(0,255).floor();
				int g = 255 - mof.green;//(mof.green * BRIGHTEN).clamp(0,255).floor();
				int b = 255 - mof.blue;//(mof.blue * BRIGHTEN).clamp(0,255).floor();

				return [r,g,b];

				//return [255,0,0];
			}
		}

		return [red,green,blue];
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

				var col = b.fillColour(x,z);

				img.data[index] = col[0];
				img.data[index+1] = col[1];
				img.data[index+2] = col[2];
				img.data[index+3] = 255;
			}
		}

		canvas.putImageData(img, ox,oz);
	}

	Biome getBiome(int x, int z, BiomeInfo biomes) {
		int index = (z*TILESIZE+x)*4;

		int id = this.data[index];
		Biome b = biomes.biomes[id];
		return b;
	}
}