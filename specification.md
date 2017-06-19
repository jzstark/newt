# Specification of Model Definition (Draft)

- Name: a general model name, such as InceptionV3, ResNet50, etc.
- URI: the location of weight file.
- Checksum: md5 checksum of both files.
- Version: version number of software
- input layer: [id, shape]
- output layer: [id, shape]
- [repeated] *Layer*

## Layer

- className: general name of this layer, such as Conv2D
- id
- upperLayer: the id of upper layer // however, users should not be responsible for id
- trainable
- config: *layer-specific parameters*

## layer-specific parameters

### Convolution2D

- activation
- activity_regularizer
- bias_constraint
- bias_initializer: {class_name, config}
- bias_regularizer
- data_format // channels_last or not
- dilation_rate
- filters
- kernel_constraint
- kernel_initializer: {name, config: {distribution, mode, scale, seed}}
- kernel_regularizer
- kernel_size
- padding
- strides

- use_bias

### BatchNormalization

- bool use_global_stats
- float moving_average_fraction
- float eps
- axis
- center
- scale
- beta_constraint
- beta_initializer
- beta_regulizer
- gamma_constraint
- gamma_initializer
- gamma_regulizer
- moving_average_initializer
- moving_variance_initializer

## Dense

- [softmax, sigmoid] type
- activity_regularizer
- bias_constraint
- bias_initializer
- bias_regularizer
- kernel_constraint
- kernel_initializer
- kernel_regularizer
- units
- use_bias
- axis

### Activation

- [relu, tanh] type
- float negative_slope (for relu only)

### Pool2D

- [MaxPool, AvgPool] type
- data_format //channels_last or first
- padding
- size
- strides

### Concatacate

- axis

### DropOut

- ratio

### Flatten

- None
