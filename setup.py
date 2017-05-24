from setuptools import setup
from setuptools import find_packages


setup(name='Newt',
      version='0.0.1',
      description='Deep Learning for Python',
      author='Roger Stark',
      author_email='rho.ajax@gmail.com',
      url='https://github.com/jzstark/newt',
      download_url='https://github.com/jzstark/newt/archive/master.zip',
      license='MIT',
      install_requires=['protobuf', 'tensorflow', 'six'],
      extras_require={
          'tests': ['pytest',
                    'pytest-pep8',
                    'pytest-xdist',
                    'pytest-cov'],
      },
      packages=find_packages())
