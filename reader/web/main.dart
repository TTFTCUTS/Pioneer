library Pioneer;

import 'dart:html';
import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:math';

import "package:archive/archive.dart";
import "package:image/image.dart";

part "pioneermap.dart";

CanvasElement canvasElement;
CanvasRenderingContext2D canvas;

PioneerMap map;
DivElement mapContainer;
Element overlayText;
bool dragging = false;
int dragx = 0;
int dragz = 0;
int mapdragx = 0;
int mapdragz = 0;

void main() {
	Element filepicker = querySelector("#file");

	filepicker.addEventListener("change", loadMapFromFile);

	canvasElement = querySelector("#canvas");
	canvas = canvasElement.context2D;
	mapContainer = querySelector("#left");

	canvasElement.addEventListener("mousemove", (MouseEvent e) {
		if (map != null) {
			map.mouseOver(e);
		}
	});

	canvasElement.addEventListener("mouseout", (MouseEvent e) {
		setOutputCoords();
	});

	canvasElement.addEventListener("dblclick", (MouseEvent e) {
		if (map != null) {
			map.doubleClick(e);
		}
	});

	window.addEventListener("resize", resizeWindow);

	mapContainer.addEventListener("mousedown", startDrag);
	window.addEventListener("mousemove", drag);
	window.addEventListener("mouseup", endDrag);

	querySelector("#filebutton").addEventListener("click", (Event e) {
		querySelector("#file").click();
	});

	overlayText = querySelector("#overlaytext");

	overlayText..addEventListener("click", (Event e) {
		querySelector("#file").click();
	});

	Map<String,String> args = Uri.base.queryParameters;

	if (args.containsKey("map")) {
		loadMapFromUrl(args["map"]);
	} else {
		overlayText..innerHtml="Click here or under the logo<br/>to load a .pioneer map.<br/><br/><span id='help'>Once rendered in-game, map files can be found in the pioneer subdirectory of the main Minecraft folder.<br/><br/>Click and drag on the map to scroll, double-click on the map or click the colour swatches next to the biome names to toggle highlighting.</span>"..style.cursor="pointer";
	}
}

void resizeCanvas(int h, int w) {
	canvasElement.width = h;
	canvasElement.height = w;

	redraw();
}

void resizeWindow([Event e]) {
	Element container = mapContainer;
	int cw = container.clientWidth;
	int ch = container.clientHeight;

	int xdiff = max(0,cw - (canvasElement.width + 20)) ~/ 2;
	int ydiff = max(0,ch - (canvasElement.height + 18)) ~/ 2;

	canvasElement.style.top = "${ydiff}px";
	canvasElement.style.left = "${xdiff}px";
}

void redraw() {
	clear();
	if (map != null) {
		map.draw();
	}
}

void clear() {
	canvas.clearRect(0,0, canvasElement.width, canvasElement.height);
}

void startDrag(MouseEvent e) {
	mapContainer.style.cursor = "all-scroll";
	dragging = true;
	dragx = 0;
	dragz = 0;

	mapdragx = mapContainer.scrollLeft + e.client.x;
	mapdragz = mapContainer.scrollTop + e.client.y;

	e.preventDefault();
}

void endDrag(MouseEvent e) {
	mapContainer.style.cursor = "crosshair";
	dragging = false;
	dragx = 0;
	dragz = 0;
	mapdragx = 0;
	mapdragz = 0;
}

void drag(MouseEvent e) {
	if (dragging) {
		dragx = e.client.x;
		dragz = e.client.y;

		mapContainer
			..scrollLeft = mapdragx - dragx
			..scrollTop = mapdragz - dragz;

		clearSelection();
	}
}

void centre() {
	mapContainer
		..scrollLeft = max(0,(mapContainer.scrollWidth - mapContainer.clientWidth) ~/2)
		..scrollTop = max(0,(mapContainer.scrollHeight - mapContainer.clientHeight) ~/2);
}

void loadMapFromFile(Event e) {
	FileUploadInputElement fin = e.target as FileUploadInputElement;
	File file = fin.files[0];

	if (file == null) {
		return;
	}

	fin.value = "";

	FileReader reader = new FileReader();
	reader.readAsArrayBuffer(file);

	reader.addEventListener("load", (ProgressEvent fe){
		FileReader r = fe.target;

		loadMapData(r.result);
	});
}

void loadMapFromUrl(String url) {

	print(url);

	HttpRequest.request(url, responseType: "arraybuffer").then((HttpRequest r) {
		ByteBuffer bytes = r.response;

		loadMapData(bytes.asUint8List());
	}).catchError((ex){

		String title = ex.toString();
		String message = "Something went wrong!<br/>And it has something to do with the message up there.";
		bool link = true;

		if (ex is Event) {
			HttpRequest r = ex.target;
			String response = r.statusText;
			int status = r.status;

			title = "$status ($response)";
			message = "Failed to get the requested url.";
			link = false;
		}

		errorMessage(title, message, link);
	});
}

void loadMapData(List<int> data) {
	Archive archive = null;

	try {
		archive = new ZipDecoder().decodeBytes(data);

		mapSetup(archive);

		querySelector("#overlay").style.display="none";
	} catch(ex, trace) {

		String message = "Something went wrong!<br/>If you are sure that the chosen file is a valid map, then please report the issue.";

		if (ex is ArchiveException) {
			message = "The chosen map file could not be unpacked correctly. Please make sure that it is a valid Pioneer map.<br/>If it was and something is still going wrong, please report the issue.";
		}

		errorMessage(ex.toString(), message);

		return;
	}
}

void errorMessage(String title, String message, [bool link = true]) {
	overlayText
		..setInnerHtml("$title<br/><br/><span id='help'>$message");

	if (link) {
		overlayText
			..appendHtml("<br/><br/>")
			..append(new AnchorElement(href: "https://github.com/TTFTCUTS/Pioneer/issues")
				..text = "Pioneer GitHub issue tracker"
				..target = "_blank"
				..addEventListener("click", (e) => e.stopPropagation()
				)
			);
	}
}

void mapSetup(Archive archive) {

	if (map != null) {
		map.destroy();
		map = null;
	}

	map = new PioneerMap(archive);

	resizeWindow();
	redraw();

	centre();

	querySelectorAll("textarea").forEach((e) => scaleTextArea(e));
}

void sortTable(TableElement table, int column, Comparator<String> comparator, [bool reversed = false]) {
	bool switching = true;
	bool shouldSwitch;
	int i;

	while (switching) {
		switching = false;
		List<TableRowElement> rows = table.rows;

		for (i = 0; i < (rows.length - 1); i++) {
			shouldSwitch = false;

			TableCellElement x = rows[i].cells[column];
			TableCellElement y = rows[i + 1].cells[column];

			if (comparator(x.innerHtml, y.innerHtml) * (reversed?-1:1) > 0) {
				shouldSwitch= true;
				break;
			}
		}
		if (shouldSwitch) {
			rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
			switching = true;
		}
	}
}

void clearSelection() {
	window.getSelection().empty();
	window.getSelection().removeAllRanges();
}

void setOutputCoords([int x, int z, Biome b]) {
	Element coords = querySelector("#coordinates");
	Element biome = querySelector("#biome");
	if (b == null) {
		coords.innerHtml = "N/A";
		biome.innerHtml = "Unknown";
	} else {
		coords.innerHtml = "x: $x z: $z";
		biome
			..innerHtml = ""
			..append(b.makeSwatch(12)..style.marginRight="6px")
			..appendText(b.name);
	}
}

void scaleTextArea(TextAreaElement e) {
	int w = 38; // textbox width, fixed
	int h = 0; // textbox height to be set to this many lines

	//print("textbox:");

	List<String> lines = e.value.split("\n");

	for(int i=0; i<lines.length; i++) {
		h++;

		//print("line ${i+1}: h=$h");

		List<String> words = lines[i].split(" ");

		int ll = 0; // current line length

		for (int j=0; j<words.length; j++) {
			int l = words[j].length + 1; // current word + space length
			if (ll > 0 && ll + l > w) {
				h++;
				ll = 0;
			}
			ll += l;
			while (ll > w) {
				ll -= w;
				h++;
			}

			//print("word ${j+1}, l=$l, ll=$ll, h=$h");
		}
	}

	//print("final h=$h");

	e.style.height = "${h.clamp(1,10) * 15 + 1}px";
}