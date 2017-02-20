library Pioneer;

import 'dart:html';
import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';

import "package:archive/archive.dart";
import "package:image/image.dart";

part "pioneermap.dart";

CanvasElement canvasElement;
CanvasRenderingContext2D canvas;

PioneerMap map;

void main() {
	Element filepicker = querySelector("#file");

	filepicker.addEventListener("change", loadMapFile);

	canvasElement = querySelector("#canvas");
	canvas = canvasElement.context2D;
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
}
