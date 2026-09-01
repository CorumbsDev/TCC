#!/usr/bin/env python3
"""Compat: redireciona para o Controlador unificado na raiz do projeto."""
import os
import runpy
import sys

_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Controlador.py"))
sys.argv[0] = _ROOT
runpy.run_path(_ROOT, run_name="__main__")
