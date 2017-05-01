==============
debian-minimal
==============

The ``debian-minimal`` element uses debootstrap for generating a
minimal image. In contrast the ``debian`` element uses the cloud-image
as the initial base.

By default this element creates the latest stable release.  The exact
setting can be found in the element's ``environment.d`` directory in
the variable ``DIB_RELEASE``.  If a different release of Debian should
be created, the variable ``DIB_RELEASE`` can be set appropriately.

.. element_deps::
