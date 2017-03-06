part of Pioneer;

class PioneerMap {
	static const int BORDER = 20;

	MapInfo mapInfo;
	BiomeInfo biomeInfo;

	List<Biome> highlights = [];

	List<MapTile> tiles;

	int xpos = 0;
	int zpos = 0;

	PioneerMap(Archive archive) {
		ArchiveFile mapinfofile = archive.findFile("map.json");
		ArchiveFile biomeinfofile = archive.findFile("biomes.json");

		if (mapinfofile == null || biomeinfofile == null) {
			throw new ArchiveException("Could not find map information files");
		}

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

				for (int i=0; i<tile.data.length; i+=4) {
					this.biomeInfo.countBiome(tile.data[i]);
				}
			}
		}

		this.biomeInfo.calcStats(this);

		querySelector("#mapinfo")
			..innerHtml = ""
			..append(this.mapInfo.makeInfoElement(this));

		querySelector("#stats")
			..innerHtml = ""
			..append(this.biomeInfo.makeBiomeElement(this));

		resizeCanvas(this.mapInfo.tileRange * MapTile.TILESIZE, this.mapInfo.tileRange * MapTile.TILESIZE);
	}

	void destroy() {

	}

	void mouseOver(MouseEvent e) {
		int wx = (e.offset.x - mapInfo.mapOffsetX - xpos) * mapInfo.skip + mapInfo.offsetX;
		int wz = (e.offset.y - mapInfo.mapOffsetZ - zpos) * mapInfo.skip + mapInfo.offsetZ;

		Biome b = this.getBiome(e.offset.x,e.offset.y);

		setOutputCoords(wx,wz,b);
	}

	void doubleClick(MouseEvent e) {
		this.toggleHighlights(this.getBiome(e.offset.x, e.offset.y));
	}

	draw() {
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

				tiles[id].draw(canvas, MapTile.TILESIZE * x + this.xpos, MapTile.TILESIZE * z + this.zpos, this.biomeInfo, this.highlights);
				//t++;
			}
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

	void setHighlights([dynamic highlight = null]) {
		this.highlights.clear();
		if (highlight is Iterable<Biome>) {
			this.highlights.addAll(highlight);
		} else if (highlight is Biome) {
			this.highlights.add(highlight);
		}
	}

	void toggleHighlights(dynamic highlight) {
		bool equals = false;

		if (highlight is Iterable<Biome>) {
			if(this.highlights.length == highlight.length && this.highlights.toSet().containsAll(highlight)) {
				equals = true;
			}
		} else if (highlight is Biome) {
			if (this.highlights.length == 1 && this.highlights[0] == highlight) {
				equals = true;
			}
		}

		if (equals) {
			this.setHighlights();
		} else {
			this.setHighlights(highlight);
		}
		this.draw();
	}
}

class MapInfo {
	String name;
	int dimension;
	String dimensionType;
	String seed;
	String generatorName;
	int generatorVersion;
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

		//print("$name (dim $dimension, $dimensionType, $generatorName v$generatorVersion), seed: $seed");
		//print("$jobSize tiles, $tileRange x $tileRange (radius $radius, scale $skip)");
		//print("origin offset: $offsetX,$offsetZ");

		this.mapOffsetX = (((MapTile.TILESIZE * tileRange) )~/2);
		this.mapOffsetZ = (((MapTile.TILESIZE * tileRange) )~/2);
	}

	Element makeInfoElement(PioneerMap map) {
		DivElement infobox = new DivElement();

		TableElement el = new TableElement();

		el.addRow()..addCell().innerHtml="World Name"..addCell().innerHtml=this.name;
		el.addRow()..addCell().innerHtml="Dimension"..addCell().innerHtml="${this.dimension} (${this.dimensionType})";

		String genver = "";
		if (this.generatorVersion != 0) {
			genver = " v${this.generatorVersion}";
		}
		el.addRow()..addCell().innerHtml="Generator"..addCell().innerHtml="${this.generatorName}$genver";
		el.addRow()..addCell().innerHtml="Seed"..addCell().innerHtml=this.seed;
		el.addRow()..addCell().innerHtml="Size"..addCell().innerHtml="${this.tileRange * MapTile.TILESIZE * this.skip}m, ${skip}:1 scale<br/>${tileRange}x${tileRange} tiles, origin ${offsetX},${offsetZ}";

		infobox.append(el);

		Element more = new DivElement()..innerHtml="More"..id="detailsbutton";

		infobox.append(more);

		Element morebox = new DivElement()..style.display="none"..id = "detailsbox";

		String command = "/pioneer ${this.radius}";
		if (this.skip != 1) {
			command += " $skip";
		}
		command += " $offsetX $offsetZ";

		morebox
			..append(new SpanElement()..innerHtml="Command:")
			..append(new TextAreaElement()..readOnly=true..value=command)
			..append(new SpanElement()..innerHtml="Generator Options:")
			..append(new TextAreaElement()..readOnly=true..value=this.generatorOptions);

		infobox.append(morebox);

		more.addEventListener("click", (MouseEvent e){
			if (morebox.style.display=="none") {
				morebox.style.display = "block";
				more.innerHtml = "Less";
			} else {
				morebox.style.display = "none";
				more.innerHtml = "More";
			}
		});

		return infobox;
	}
}

class BiomeInfo {
	Map<int, Biome> biomes = new HashMap<int, Biome>();
	Map<String, Biome> biomesByName = new HashMap<String, Biome>();

	Map<Biome, BiomeStats> statistics = new HashMap<Biome, BiomeStats>();
	int mutationCount = 0;
	double mutationRate = 0.0;

	static Comparator<String> compare_percent = (String a, String b) {
		double pa = double.parse(a.substring(0, a.length-1));
		double pb = double.parse(b.substring(0, b.length-1));

		return pb.compareTo(pa);
	};

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

	void countBiome(int id) {
		Biome b = this.biomes[id];
		Biome category = b;

		if (b.mutation) {
			category = biomes[b.mutationOf];
			mutationCount++;
		}

		if (!statistics.containsKey(category)) {
			statistics[category] = new BiomeStats();
		}

		BiomeStats stats = statistics[category];

		stats.count++;

		if (!stats.subcounts.containsKey(b)) {
			stats.subcounts[b] = 0;
		}

		stats.subcounts[b]++;
	}

	void calcStats(PioneerMap map) {
		this.mutationRate = this.mutationCount / (map.mapInfo.tileRange * map.mapInfo.tileRange * MapTile.TILESIZE * MapTile.TILESIZE);
	}

	Element makeBiomeElement(PioneerMap map) {
		DivElement div = new DivElement();

		div.append(new SpanElement()..innerHtml = "Mutation rate: ${(mutationRate * 100.0).toStringAsFixed(3)}%"..title="Mutation biomes are rare biome variants such as Sunflower Plains, Flower Forest or Mesa Bryce. Mutations are grouped with their parent biome in the list below.");
		div..append(new BRElement())..append(new BRElement());

		TableElement element = new TableElement()..className="biometable";

		int divisor = map.mapInfo.tileRange * MapTile.TILESIZE;
		divisor *= divisor;

		for (Biome b in this.statistics.keys) {
			BiomeStats stats = this.statistics[b];

			TableRowElement row = element.addRow();

			Element c = row.addCell();

			Element box = b.makeSwatch(11)..style.marginTop="1px"..addEventListener("click", (Event e){
				if (map != null) {
					map.toggleHighlights(stats.subcounts.keys);
				}
			});

			c.append(box);

			DivElement moreinfo = new DivElement()..className="biomeinfo"..style.display="none";

			// sub info

			TableElement subinfo = new TableElement()..className="biomesubinfo";

			for (Biome sb in stats.subcounts.keys) {
				TableRowElement subrow = subinfo.addRow();

				subrow.addCell().append(sb.makeSwatch(11)..addEventListener("click", (Event e){
					if (map != null) {
						map.toggleHighlights(sb);
					}
				}));

				TableCellElement datacell = subrow.addCell();
				datacell.innerHtml = sb.name;

				TableElement databox = new TableElement()..className="biomedata";

				databox.addRow()..addCell().innerHtml="ID"..addCell().innerHtml="${sb.id}";
				databox.addRow()..addCell().innerHtml="Temp."..addCell().innerHtml=sb.temperature.toStringAsFixed(3);
				databox.addRow()..addCell().innerHtml="Moisture"..addCell().innerHtml=sb.moisture.toStringAsFixed(3);
				databox.addRow()..addCell().innerHtml="Height"..addCell().innerHtml="${sb.baseHeight.toStringAsFixed(3)} &plusmn; ${sb.heightVariation.toStringAsFixed(3)}";
				databox.addRow()..addCell().innerHtml="Rains?"..addCell().innerHtml=sb.canRain ? "Yes" : "No";
				databox.addRow()..addCell().innerHtml="Snowy?"..addCell().innerHtml=sb.snowy ? "Yes" : "No";

				subrow.addCell().innerHtml = "${((stats.subcounts[sb] / divisor) * 100).toStringAsFixed(2)}%";

				datacell.append(databox);
			}

			sortTable(subinfo, 2, compare_percent);

			moreinfo.append(subinfo);

			// end sub info

			row.addCell()..style.width="185px"..innerHtml = "${b.name}"..append(moreinfo);

			Element morebutton = new DivElement()..className="biomesmore";

			Element symbol = new DivElement()..innerHtml="+";
			morebutton.append(symbol);

			row.addCell().append(morebutton);

			row.addCell()..className="percent"..innerHtml = "${((stats.count / divisor) * 100).toStringAsFixed(2)}%";

			morebutton.addEventListener("click", (Event e){
				if (moreinfo.style.display == "none") {
					moreinfo.style.display = "block";
					symbol.innerHtml = "&minus;";
				} else {
					moreinfo.style.display = "none";
					symbol.innerHtml = "+";
				}
				clearSelection();
				e.preventDefault();
			});

		}

		sortTable(element, 3, compare_percent);

		div.append(element);

		return div;
	}
}

class BiomeStats {
	int count = 0;

	Map<Biome, int> subcounts = {};
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

		//print("$id - $name: temp: $temperature, moisture: $moisture, height: $baseHeight~$heightVariation, rain: $canRain, snow: $snowy");
		//print("Mutation: $mutation , of $mutationOf");
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

	List<int> fillColour(int x, int z, [bool bright = true]) {
		int r = red;
		int g = green;
		int b = blue;

		if (this.mutation) {
			if ((x+z) % 4 == 0) { //((x+z)~/2) %2 == 0
				Biome mof = this.parent.biomes[this.mutationOf];

				r = 255 - mof.red;//(mof.red * BRIGHTEN).clamp(0,255).floor();
				g = 255 - mof.green;//(mof.green * BRIGHTEN).clamp(0,255).floor();
				b = 255 - mof.blue;//(mof.blue * BRIGHTEN).clamp(0,255).floor();
			}
		}

		if (!bright) {
			r ~/= 5;
			g ~/= 5;
			b ~/= 5;
		}

		return [r,g,b];
	}

	Element makeSwatch(int size) {
		CanvasElement swatch = new CanvasElement(width:size,height:size)..className="swatch";
		var s = swatch.context2D;

		ImageData data = s.getImageData(0,0,size,size);

		for (int x=0; x<size; x++) {
			for (int z=0; z<size; z++) {
				int index = (z * size + x) * 4;

				List<int> col = this.fillColour(x,z);

				data.data[index] = col[0];
				data.data[index+1] = col[1];
				data.data[index+2] = col[2];
				data.data[index+3] = 255;
			}
		}

		s.putImageData(data,0,0);

		return swatch;
	}
}

class MapTile {
	static const int TILESIZE = 128;

	int tilex;
	int tilez;
	Uint8List data;

	MapTile(Uint8List this.data, int this.tilex, int this.tilez) {

	}

	void draw(CanvasRenderingContext2D canvas, int ox, int oz, BiomeInfo biomes, List<Biome> highlights) {
		ImageData img = canvas.getImageData(ox,oz,TILESIZE,TILESIZE);

		//print("############################");
		for (int x=0; x<TILESIZE; x++) {
			for (int z=0; z<TILESIZE; z++) {
				int index = (z*TILESIZE+x)*4;

				int id = this.data[index];
				Biome b = biomes.biomes[id];

				var col = b.fillColour(x,z, highlights.isEmpty || highlights.contains(b));

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