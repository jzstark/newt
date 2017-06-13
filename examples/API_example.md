# Learning

```python
import newt
tfmodel = newt.models.from_tensorflow(sess)
newt.models.save_model(tfmodel, model_dir, include_variables=True)
# newt.util.push_model()
```

# Inference

```python
import newt

# Load Model
newt.util.pull_model(model_name, model_dir)
model = newt.models.load_model(model_path/json_file)
model.load_weight(model_path/numpy_file)
# View Layer
print model.layers
input_layer =  model.layers['input'] # The name has to be unique
input_prec = input_layer.prec # tf.float32
input_shape = input_layer.shape # (None, 28, 28, 1)

'''Case 1: convert to TF code at the very begining...'''
import_info = newt.models.to_tensorflow(model, sess) # Not necessarily sess
print import_info
# The rest are all in native tensorflow code...

''' Case 2: Convert whatever is required by native code to tensorflow format'''
tfgraph = newt.models.to_tensorflow(model)
tfvar   = model.variables.to_tensorflow
print tfvar
accuracy = tfvar['accuracy'] # Actually accuracy is a well-known metric
print accuracy.desc # for usage help

BATCH = tfvar['valid_batch']
logits = tfvar['logits']
fc1_weights = tfvar['fc1_weights']
fc2_weights = tfvar['fc2_weights']
fc1_biases  = tfvar['fc1_biases']
fc2_biases  = tfvar['fc2_biases']

''' Case 3: Do all required modification on the local newt model, and only
export for tensorflow use after everything is ready.
'''
model.replace_layer('input', newt.layer.inputLayer(input_prec, input_shape))
model.replace_layer('output', newt.layer.softmax(5))
model.delete_layer(['dropout_0', 'dropout_1'])
newt.models.to_tensorflow(model, sess)
```
