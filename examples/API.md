# Inference

```python
import newt.tensorflow as newtf

# Load Model
model_path = ...
newt.pull()
model = newtf.load(json_file)
model.load_weight(numpy_file)

# Layer Replacement
print model.layers
print model.layers['input']
test_labels = tf.placeholder(tf.float32, shape=(None, 28, 28, 1))
model.replace_layer('input', test_labels)

# Layer Delete
print model.layers['dropout_0']
model.delete_layer('dropout_0')

# Layer Add
```
