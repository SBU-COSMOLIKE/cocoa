# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'CoCoA'
copyright = '2025, Tim Eifler, Elisabeth Krause, Vivian Miranda and the Cosmolike Org'
author = 'Tim Eifler, Elisabeth Krause, Vivian Miranda and the Cosmolike Org'
release = '2020'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "myst_parser",
    "sphinxemoji.sphinxemoji"
]

myst_enable_extensions = [
    "dollarmath",
    "amsmath",
]

templates_path = []

source_suffix = {
    ".rst": "restructuredtext",
    ".md": "markdown",
}

master_doc = "index"

exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

language = "en"


# -- Options for HTML output -------------------------------------------------
html_theme = 'alabaster'
html_static_path = ['_static']
html_css_files = ['custom.css']
show_authors = True

# Output file base name for HTML help builder.
htmlhelp_basename = "cocoadoc"


# GPT code for rendering GitHub [TIP] and [Note]
import emoji, re
from docutils import nodes
from docutils.parsers.rst import Directive
from sphinx.transforms import SphinxTransform

_CALLOUT_RE = re.compile(r'^\s*\[!\s*(TIP|NOTE|WARNING|IMPORTANT|CAUTION)\s*\]\s*', re.I)
_KIND_MAP = {
  'tip': 'tip',
  'note': 'note',
  'warning': 'warning',
  'important': 'important',
  'caution': 'caution',
}

def _in_code(node):
    p = node.parent
    while p:
        if isinstance(p, (nodes.literal_block, nodes.literal)):
            return True
        p = p.parent
    return False

class GithubAdmonitionTransform(SphinxTransform):
  default_priority = 210  # after parsing

  def apply(self):
    for p in list(self.document.traverse(nodes.paragraph)):
      if _in_code(p):
        continue
      txt = p.astext()
      m = _CALLOUT_RE.match(txt)
      if not m:
        continue
      kind = _KIND_MAP[m.group(1).lower()]
      body = _CALLOUT_RE.sub('', txt, count=1)  # remove the [!...] tag cleanly
      admon = nodes.admonition('', classes=[kind])
      admon += nodes.paragraph(text=body)
      p.replace_self(admon)

def _is_in_code(node):
    p = node.parent
    while p:
        if isinstance(p, (nodes.literal_block, nodes.literal)):
            return True
        p = p.parent
    return False

class EmojiShortcodeTransform(SphinxTransform):
    default_priority = 700  # after parsing, before writing
    def apply(self):
        for text_node in list(self.document.traverse(nodes.Text)):
            if _is_in_code(text_node):
                continue
            original = text_node.astext()
            # Convert GitHub-style :shortcode: to Unicode emoji
            converted = emoji.emojize(original, language="alias")
            if converted != original:
                text_node.parent.replace(text_node, nodes.Text(converted))

def setup(app):
  app.add_transform(EmojiShortcodeTransform)
  app.add_transform(GithubAdmonitionTransform)