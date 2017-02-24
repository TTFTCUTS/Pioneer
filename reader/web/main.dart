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

	canvasElement.addEventListener("mousemove", (MouseEvent e) {
		if (map != null) {
			map.mouseOver(e);
		}
	});

	canvasElement.addEventListener("mousedown", startDrag);
	window.addEventListener("mousemove", drag);
	window.addEventListener("mouseup", endDrag);

	window.addEventListener("resize", (Event e){
		resize();
	});

	resize();
}

void resize() {

	Element box = querySelector("#left");

	canvasElement.width = box.clientWidth;
	canvasElement.height = box.clientHeight;

	redraw();
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
	canvasElement.style.cursor = "all-scroll";
	dragging = true;
	dragx = 0;
	dragz = 0;
	if (map != null) {
		mapdragx = map.xpos;
		mapdragz = map.zpos;
	} else {
		mapdragx = 0;
		mapdragz = 0;
	}
}

void endDrag(MouseEvent e) {
	canvasElement.style.cursor = "crosshair";
	dragging = false;
	dragx = 0;
	dragz = 0;
	mapdragx = 0;
	mapdragz = 0;
}

void drag(MouseEvent e) {
	if (dragging) {
		dragx += e.movement.x;
		dragz += e.movement.y;

		if (map != null) {
			map.moveTo(mapdragx + dragx, mapdragz + dragz);
			redraw();
		}
		window.getSelection().empty();
		window.getSelection().removeAllRanges();
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