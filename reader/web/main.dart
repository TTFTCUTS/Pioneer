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
bool dragging = false;
int dragx = 0;
int dragz = 0;
int mapdragx = 0;
int mapdragz = 0;

void main() {
	Element filepicker = querySelector("#file");

	filepicker.addEventListener("change", loadMapFile);

	canvasElement = querySelector("#canvas");
	canvas = canvasElement.context2D;
	mapContainer = querySelector("#left");

	canvasElement.addEventListener("mousemove", (MouseEvent e) {
		if (map != null) {
			map.mouseOver(e);
		}
	});

	window.addEventListener("resize", resizeWindow);

	mapContainer.addEventListener("mousedown", startDrag);
	window.addEventListener("mousemove", drag);
	window.addEventListener("mouseup", endDrag);

	querySelector("#filebutton").addEventListener("click", (Event e) {
		querySelector("#file").click();
	});
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
	/*if (map != null) {
		mapdragx = map.xpos;
		mapdragz = map.zpos;
	} else {
		mapdragx = 0;
		mapdragz = 0;
	}*/

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

void loadMapFile(Event e) {
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

		Archive a = new ZipDecoder().decodeBytes(r.result);

		mapSetup(a);
	});
}

void mapSetup(Archive archive) {

	if (map != null) {
		map.destroy();
		map = null;
	}

	map = new PioneerMap(archive);

	resizeWindow();
	redraw();
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