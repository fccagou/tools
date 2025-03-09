#!/usr/bin/python3

import sys
import json
from typing import Any, Dict, List, Union

def json_to_yaml(json_obj: Union[Dict[str,Any], List[Any], str,int, float, bool], indent: int = 0) -> str:
    yaml_str = ""
    if isinstance(json_obj, dict):
        for key, value in json_obj.items():
            yaml_str += " " * indent + f"{key}:"
            if isinstance(value, list) or isinstance(value, dict):
                yaml_str += "\n"
            yaml_str += json_to_yaml(value, indent + 2)
    elif isinstance(json_obj, list):
        if indent > 0:
            indent -= 2
        for item in json_obj:
            yaml_str += " " * indent + f"- "
            yaml_str += json_to_yaml(item, indent + 2).lstrip()
    else:
        yaml_str += f" {json_obj}\n"
    return yaml_str

def convert_json_to_yaml(json_string: str) -> str:
    json_obj = json.loads(json_string)
    yaml_str = json_to_yaml(json_obj)
    return yaml_str

json_string='''
{
    "nom": "fc",
    "age": 53,
    "est_etudiant": false,
    "matieres": ["Math", "Physics"],
    "adresse": {
        "rue": "1, rue du port",
        "Ville": "Port Vila"
    }
}'''





json_string = sys.stdin.read()
yaml_string = convert_json_to_yaml(json_string)
print ( yaml_string)





