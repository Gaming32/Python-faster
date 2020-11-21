import setuptools

setuptools.setup(
    name = 'Python-Gravity',
    version = '1.0.0b5',
    url = 'https://github.com/gaming32/pygravity',
    author = 'Gaming32',
    author_email = 'gaming32i64@gmail.com',
    license = 'License :: OSI Approved :: MIT License',
    description = 'Library for calculating stuff having to do with gravity',
    long_description = '',
    long_description_content_type = 'text/markdown',
    package_data = {
        'faster': [
            'py.typed',
            'fastlist.pyi',
        ],
    },
    packages = [
        'faster',
    ],
    ext_modules = [
        setuptools.Extension('faster.fastlist', ['faster/fastlist.c']),
    ],
    zip_safe = False,
)
