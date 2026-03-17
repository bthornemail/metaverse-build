#!/usr/bin/env awk -f

function die(msg) {
  print "ERROR: " msg > "/dev/stderr"
  exit 2
}

function trim(s) {
  gsub(/^[ \t\r\n]+/, "", s)
  gsub(/[ \t\r\n]+$/, "", s)
  return s
}

function canon_cp(raw, cp) {
  cp = toupper(trim(raw))
  gsub(/^U\+/, "", cp)
  if (cp !~ /^[0-9A-F]+$/) {
    die("invalid codepoint format: " raw)
  }
  return cp
}

function add_cp_input(cp) {
  if (!(cp in input_seen)) {
    input_seen[cp] = 1
    input_count += 1
    input_order[input_count] = cp
  }
}

function add_cp_word(cp, word, key) {
  key = cp SUBSEP word
  if (!(key in cp_word_seen)) {
    cp_word_seen[key] = 1
    cp_word_count[cp] += 1
    cp_word_list[cp, cp_word_count[cp]] = word
  }
}

function add_synset_word(syn, word, key) {
  if (!(syn in syn_seen)) {
    syn_seen[syn] = 1
    syn_count += 1
    syn_order[syn_count] = syn
  }
  key = syn SUBSEP word
  if (!(key in syn_word_seen)) {
    syn_word_seen[key] = 1
    syn_word_count[syn] += 1
    syn_word_list[syn, syn_word_count[syn]] = word
  }
}

function load_ucd(path, line, f, cp) {
  while ((getline line < path) > 0) {
    line = trim(line)
    if (line == "" || line ~ /^#/) continue
    split(line, f, "\t")
    if (length(f) != 6) die("ucd.tsv malformed line: " line)
    cp = canon_cp(f[1])
    if (cp in u_name) die("duplicate ucd codepoint: " cp)
    u_name[cp] = f[2]
    u_cat[cp] = f[3]
    u_comb[cp] = f[4]
    u_bidi[cp] = f[5]
    u_script[cp] = f[6]
  }
  close(path)
}

function load_cp_words(path, line, f, cp, word) {
  while ((getline line < path) > 0) {
    line = trim(line)
    if (line == "" || line ~ /^#/) continue
    split(line, f, "\t")
    if (length(f) != 2) die("codepoint_words.tsv malformed line: " line)
    cp = canon_cp(f[1])
    word = trim(f[2])
    if (word == "") die("empty word for codepoint: " cp)
    add_cp_word(cp, word)
  }
  close(path)
}

function load_lexicon(path, line, f, word) {
  while ((getline line < path) > 0) {
    line = trim(line)
    if (line == "" || line ~ /^#/) continue
    split(line, f, "\t")
    if (length(f) != 3) die("lexicon.tsv malformed line: " line)
    word = trim(f[1])
    if (word in w_synset) die("duplicate lexicon word: " word)
    w_pos[word] = trim(f[2])
    w_synset[word] = trim(f[3])
    if (w_pos[word] == "" || w_synset[word] == "") die("lexicon empty field: " line)
  }
  close(path)
}

function load_fano(path, line, f, syn) {
  while ((getline line < path) > 0) {
    line = trim(line)
    if (line == "" || line ~ /^#/) continue
    split(line, f, "\t")
    if (length(f) != 3) die("fano.tsv malformed line: " line)
    syn = trim(f[1])
    if (syn in syn_point) die("duplicate fano synset: " syn)
    syn_point[syn] = trim(f[2])
    syn_line[syn] = trim(f[3])
    if (syn_point[syn] == "" || syn_line[syn] == "") die("fano empty field: " line)
  }
  close(path)
}

BEGIN {
  if (ucd_path == "" || cp_words_path == "" || lexicon_path == "" || fano_path == "") {
    die("missing required -v paths (ucd_path/cp_words_path/lexicon_path/fano_path)")
  }

  load_ucd(ucd_path)
  load_cp_words(cp_words_path)
  load_lexicon(lexicon_path)
  load_fano(fano_path)

  print "VERSION\tcodepoint-synset.v0"
}

{
  raw = trim($0)
  if (raw == "" || raw ~ /^#/) next

  cp = canon_cp(raw)
  if (!(cp in u_name)) die("unknown codepoint: " cp)
  add_cp_input(cp)
}

END {
  print "CODEPOINT_COUNT\t" input_count

  for (i = 1; i <= input_count; i++) {
    cp = input_order[i]
    print "CP\t" cp "\tname=" u_name[cp] "\tcat=" u_cat[cp] "\tcomb=" u_comb[cp] "\tbidi=" u_bidi[cp] "\tscript=" u_script[cp]

    wc = cp_word_count[cp] + 0
    for (j = 1; j <= wc; j++) {
      word = cp_word_list[cp, j]
      if (!(word in w_synset)) die("word missing from lexicon: " word)
      syn = w_synset[word]
      if (!(syn in syn_point)) die("synset missing fano mapping: " syn)
      print "WORD\t" cp "\tword=" word "\tpos=" w_pos[word] "\tsynset=" syn
      add_synset_word(syn, word)
    }
  }

  for (i = 1; i <= syn_count; i++) {
    syn = syn_order[i]
    words_csv = ""
    wc = syn_word_count[syn] + 0
    for (j = 1; j <= wc; j++) {
      if (j > 1) words_csv = words_csv ","
      words_csv = words_csv syn_word_list[syn, j]
    }
    print "SYNSET\t" syn "\twords=" words_csv "\tfano_point=" syn_point[syn] "\tfano_line=" syn_line[syn]
  }
}
