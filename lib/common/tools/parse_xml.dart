import 'dart:convert';

import 'package:xml/xml.dart' as xml;

class ParseXml {
  String mapToXml(Map<String, dynamic> map, String rootElementName) {
    final rootElement = xml.XmlElement(xml.XmlName('prestashop'), []);
    final childElement = xml.XmlElement(xml.XmlName(rootElementName), []);
    _addXmlElements(childElement, map);
    rootElement.children.add(childElement);
    final document = xml.XmlDocument([rootElement]);
    return document.toXmlString(pretty: true);
  }

  Map<String, dynamic> xmlToMap(String xmlString) {
    final document = xml.XmlDocument.parse(xmlString);
    final rootElement = document.rootElement;
    return _getMapFromXmlElement(rootElement);
  }

  void _addXmlElements(xml.XmlElement parentElement, dynamic value,
      {String? listKey}) {
    if (value is Map<String, dynamic>) {
      for (var key in value.keys) {
        var childElement = xml.XmlElement(xml.XmlName(key), []);
        parentElement.children.add(childElement);
        _addXmlElements(childElement, value[key], listKey: key);
      }
    } else if (value is List) {
      for (var item in value) {
        if (item is Map<String, dynamic>) {
          _addXmlElements(parentElement, item);
        } else {
          parentElement.children.add(xml.XmlText(item.toString()));
        }
      }
    } else {
      parentElement.children.add(xml.XmlText(value.toString()));
    }
  }

  Map<String, dynamic> _getMapFromXmlElement(xml.XmlElement element) {
    final map = <String, dynamic>{};
    if (element.children.isEmpty) {
      map[element.name.toString()] = element.text;
    } else {
      element.children.forEach((child) {
        if (child is xml.XmlElement) {
          if (map[child.name.toString()] == null) {
            map[child.name.toString()] = _getMapFromXmlElement(child);
          } else if (map[child.name.toString()] is List) {
            map[child.name.toString()].add(_getMapFromXmlElement(child));
          } else {
            map[child.name.toString()] = [
              map[child.name.toString()],
              _getMapFromXmlElement(child)
            ];
          }
        }
      });
    }
    return map;
  }
}
