from __future__ import print_function
from __future__ import absolute_import

import os
import sys
import tarfile
from six.moves import urllib

# Should be put into a config file
supported_model = ['lenet']
server = '207.154.194.38'
model_suffix = ['tgz', 'pbtxt', 'npy'] # should consider multiple suffixes

def supported(name):
    return name in supported_model

def pull_model(model_name, model_dir='~/models'):
    """
    # Arguments
        model_name:
    # Raises
        TypeError: if the requested name cannot be found
    """
    if not supported(model_name):
        raise TypeError('Model not supported:', model_name)

    filename = model_name + '.tgz'
    model_url = 'http://' + '/'.join([server, filename])

    dest_directory = os.path.expanduser(model_dir)
    if not os.path.exists(dest_directory):
        os.makedirs(dest_directory)

    filepath = os.path.join(dest_directory, filename)
    if not os.path.exists(filepath): # the original file will be deleted
        def _progress(count, block_size, total_size):
            sys.stdout.write('\r>> Downloading %s %.1f%%' % (
                filename, float(count * block_size) / float(total_size) * 100.0))
            sys.stdout.flush()
        print('model_url:', model_url)
        filepath, _ = urllib.request.urlretrieve(model_url, filepath, _progress)
        print()
        statinfo = os.stat(filepath)
        print('Successfully downloaded', filename, statinfo.st_size, 'bytes.')
    #print(filepath)
    tarfile.open(filepath, 'r:gz').extractall(dest_directory)

    return os.path.join(dest_directory, model_name)
