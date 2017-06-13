# Specification of Model Definition (Draft)

## Global metadata

- Name: a general model name, such as InceptionV3, ResNet50, etc.
- URI: the location of weight file.
- Checksum: md5 checksum of both files.
- Version: version number of software
- ...


## Layer

- classType: general name of this layer, such as Conv2D
- name: unique id, such as conv2d_0
- dtype: data type, such as float32
- data_format: specify chennels_first or not
- padding: valid
- bottom: bottom layer name
- top: top layer name
- shape
- seed
- Other layer-specific parameters, e.g.
  + activation: relu, tanh, etc. for Conv
  + stride for Pool
  + ...

## Variables

- Pre-defined metric, e.g. accuracy
- Constant, e.g. batch/input size
- weight variables, e.g. w and b in y = x*w + b
