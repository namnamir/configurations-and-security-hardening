# Basics
- YAML stands for *YAML Ain’t Markup Language*.
- It is similar to XML or JSON.
- YAML files usually store configuration data.
- To define a YAML file we use either `.yml` or `.yaml` as file extension.
- YAML is case sensitive.
- Key-value pairs are represented using the following syntax: `<key>: <value>`
- YAML stream is a collection of zero or more documents.
  - An empty stream contains no documents.
  - A single document may or may not be marked with `---`.
  - Different documents are separated using three dashes `---`.
  - Documents could end with `...`.
- Items of a list in YAML are represented by preceding it with `-` (hyphen).
- Any text after `#` is considered a comment.
  - YAML does not support block or multi-line comments.

# Data types in YAML
- A name followed by a colon (`:`) and a single space (` `) defines a variable.
- Variables can also be referred to as scalars.
- The following is the list of supported data types:
  - Boolean
  - Numbers (integer, and float)
  - Strings
  - Timestamp
  - Null
- YAML can auto-detect the data types, but users can also specify the type they need. To force a type, you can prefix the type with a `!!` symbol.
```YAML
# STRING
list of texts:
  - Hello World!
  - 'single quoted string'
  - " double quoted strings"
text 0: | 
  Every line in this text 
  will be stored 
  as separate lines.
text 1: > 
  This text will
  be wrapped into
  a single paragraph
name: !!str "James"
message: !!str "This is a \n multiline text"

#
# INTEGER
#
negative: !!int -12 
zero: !!int 0
positive: !!int 23
binary: !!int 0b101010
octal: !!int 01672
hexadecimal: !!int 0x1C7A
number: !!int +687_456
sexagesimal: 180:30:20 # base 60

#
# FLOAT
#
negative: !!float -1.23
zero: !!float 0.0
positive: !!float 2.3e4
infinity: !!float .inf
not a number: !!float .nan

#
# BOOLEAN
#
married: !!bool true
odd: !!bool false

#
# NULL
#
manager: !!null null
tilde: ~
title: null
~: null key

#
# TIMESTAMP
#
time: 2020-12-07T01:02:59:34.02Z
timestamp: 2020-12-07T01:02:59:34.02 +05:30
datetime: 2020-12-07T01:02:59:34.02+05:30
notimezone: 2020-12-07T01:02:59:34.02
date: 2020-12-07
```
## String (`!!str`)
- Strings can be written without quotes or enclosed in `''`(quotes) or `""` (double quotes).
- A `|` character denotes a string with newlines; indentations and spaces preserved.
- A `>` character denotes a string with newlines folded.

## NULL (`~`)
- Null represents a lack of value.
- You can also use a tilde ~, null in lowercase, NULL in uppercase, or Null in camelCase.

## Timestamp
- It uses the notation form ISO8601.
- If no time zone is added, then it is assumed to be in UTC.

# Data Type

## Array
- Arrays or Lists are used to represent a list of items or values. They are also referred to as _sequences_ in YAML.
### Block Sequence
- The block sequence style of YAML represents Arrays by using hyphens (`-)` followed by white space (` `).
```YAML
colors: 
  - red
  - green
  - blue
  - orange
```
### Flow Sequence
- The flow sequence style of YAML uses brackets and commas to represent arrays.
```YAML
colors: [red, green, blue, orange]
```

## Sequence (`!!seq`)
- Sequence represents a collection indexed by sequential integers.
- Sequences and Mappings in YAML can be nested within each other.
```YAML
# Ordered sequence of nodes
## normal version
normal: !!seq
  - red
  - orange
  - yellow

## compact version
compact: [red, orange, yellow]
```
### Sparse Sequence
- A sequence where not all the keys have values
```YAML
sparse: 
  - red
  - ~
  - blue
  - Null
  - NULL
  - orange
```
### Nested sequence
- A nested sequence represents a sequence of items and sub-items.
```YAML
sparse: 
  - red
  - blue
    - brown
    - NULL
```

## Mappings (`!!map`)
- Mappings are used to store a name-value pair.
### Nested Mappings
- In a nested mapping, a value in a mapping can be another mapping.
- There is also a compact notation using `{}` for maps.

```YAML
# normal version
a: 1
b: 
  c: 3
  d: 4

# compact version
a: 1
b: {c: 3, d: 4}
```

## Pairs (`!!pairs`)
- Pairs are ordered lists of named values that allow duplicates.
```YAML
Block tasks: 
  - meeting: standup
  - meeting: demo
  - break: lunch
  - meeting: all hands

# flow style and explicit type
Flow tasks: !!pairs [ meeting: standup, meeting: lunch ]
```

## Set (`!!set`)
- A set is an unordered collection of nodes with distinct values.
```YAML
players:
  ? Mark
  ? Steve
  ? Smith

# flow style and explicit type
soccer teams: !!set { Chelsea, Arsenal, Liverpool }
```

## Dictionary (`!!omap`)
- A dictionary is an ordered sequence of name value pairs where a value in the mapping can be a sequence.
- List members are denoted by a leading hyphen (`-`).
```YAML
Fruits:
  - Apple:  
      calories: 120
      fat: 0.2 g
      carbs: 35 g
  - Banana: 
      calories: 105
      fat: 0.4 g
      carbs: 27 g
```

### Source
- [Introduction to YAML](https://www.educative.io/courses/introduction-to-yaml)
