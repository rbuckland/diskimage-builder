Building An Image
=================

Now that you have diskimage-builder properly :doc:`installed <installation>`
you can get started by building your first disk image.

VM Image
--------

Our first image is going to be a bootable vm image using one of the standard
supported distribution :doc:`elements <../elements>` (Ubuntu or Fedora).

The following command will start our image build (distro must be either
'ubuntu' or 'fedora'):

::

    disk-image-create <distro> vm

This will create a qcow2 file 'image.qcow2' which can then be booted.

Elements
--------

It is important to note that we are passing in a list of
:doc:`elements <../elements>` to disk-image-create in our above command. Elements
are how we decide what goes into our image and what modifications will be
performed.

Some elements provide a root filesystem, such as the ubuntu or fedora element
in our example above, which other elements modify to create our image. At least
one of these 'distro elements' must be specified when performing an image
build. It's worth pointing out that there are many distro elements (you can even
create your own), and even multiples for some of the distros. This is because
there are often multiple ways to install a distro which are very different.
For example: One distro element might use a cloud image while another uses
a package installation tool to build a root filesystem for the same distro.

Other elements modify our image in some way. The 'vm' element in our example
above ensures that our image has a bootloader properly installed. This is only
needed for certain use cases and certain output formats and therefore it is
not performed by default.

Output Formats
--------------

By default a qcow2 image is created by the disk-image-create command. Other
output formats may be specified using the `-t <format>` argument. Multiple
output formats can also be specified by comma separation. The supported output
formats are:

 * qcow2
 * tar
 * tgz
 * squashfs
 * vhd
 * docker
 * raw

Disk Image Layout
-----------------

When generating a vm block image (e.g. qcow2 or raw), by default one
image with one partition holding all files is created.

The configuration is done by means of the environment variable
`DIB_BLOCK_DEVICE_CONFIG`.  This variable must hold YAML structured
configuration data.

The default is:

::

    DIB_BLOCK_DEVICE_CONFIG='
      - local_loop:
          name: image0

      - partitioning:
          base: image0
          label: mbr
          partitions:
            - name: root
              flags: [ boot, primary ]
              size: 100%'

In general each module that depends on another module has a `base`
element that points to the depending base.

Limitations
+++++++++++
The appropriate functionality to use multiple partitions and even LVMs
is currently under development; therefore the possible configuration
is currently limited, but will get more flexible as soon as all the
functionality is implemented.

In future this will be a list of some elements, each describing one
part of block device setup - but because currently only `local_loop`
and `partitioning` are implemented, it contains only the configuration
of these steps.

Currently it is possible to create multiple local loop devices, but
all but the `image0` will be not useable (are deleted during the
build process).

Currently only one partitions is used for the image.  The name of this
partition must be `root`.  Other partitions are created but not
used.

Level 0
+++++++

Module: Local Loop
..................

This module generates a local image file and uses the loop device to
create a block device from it.  The symbolic name for this module is
`local_loop`.

Configuration options:

name
  (mandatory) The name of the image.  This is used as the name for the
  image in the file system and also as a symbolic name to be able to
  reference this image (e.g. to create a partition table on this
  disk).

size
  (optional) The size of the disk. The size can be expressed using
  unit names like TiB (1024^4 bytes) or GB (1000^3 bytes).
  Examples: 2.5GiB, 12KB.
  If the size is not specified here, the size as given to
  disk-image-create (--image-size) or the automatically computed size
  is used.

directory
  (optional) The directory where the image is created.

Example:

::
        local_loop:
          name: image0

        local_loop:
          name: data_image
          size: 7.5GiB
          directory: /var/tmp

This creates two image files and uses the loop device to use them as
block devices.  One image file called `image0` is created with
default size in the default temp directory.  The second image has the
size of 7.5GiB and is created in the `/var/tmp` folder.

Please note that due to current implementation restrictions it is only
allowed to specify one local loop image.

Level 1
+++++++

Module: Partitioning
....................

This module generates partitions into existing block devices.  This
means that it is possible to take any kind of block device (e.g. LVM,
encrypted, ...) and create partition information in it.

The symbolic name for this module is `partitioning`.

Currently the only partitioning layout is Master Boot Record `MBR`.

It is possible to create primary or logical partitions or a mix of
them. The numbering of the logical partitions will typically start
with `5`, e.g. `/dev/vda5` for the first partition, `/dev/vda6` for
the second and so on.

The number of partitions created by this module is theoretical
unlimited and it was tested with more than 1000 partitions inside one
block device.  Nevertheless the Linux kernel and different tools (like
`parted`, `sfdisk`, `fdisk`) have some default maximum number of
partitions that they can handle.  Please consult the documentation of
the appropriate software you plan to use and adapt the number of
partitions.

Partitions are created in the order they are configured.  Primary
partitions - if needed - must be first in the list.

There are the following key / value pairs to define one disk:

base
   (mandatory) The base device where to create the partitions in.

label
   (mandatory) Possible values: 'mbr'
   This uses the Master Boot Record (MBR) layout for the disk.
   (There are currently plans to add GPT later on.)

align
   (optional - default value '1MiB')
   Set the alignment of the partition.  This must be a multiple of the
   block size (i.e. 512 bytes).  The default of 1MiB (~ 2048 * 512
   bytes blocks) is the default for modern systems and known to
   perform well on a wide range of targets [6].  For each partition
   there might be some space that is not used - which is `align` - 512
   bytes.  For the default of 1MiB exactly 1048064 bytes (= 1 MiB -
   512 byte) are not used in the partition itself.  Please note that
   if a boot loader should be written to the disk or partition,
   there is a need for some space.  E.g. grub needs 63 * 512 byte
   blocks between the MBR and the start of the partition data; this
   means when grub will be installed, the `align` must be set at least
   to 64 * 512 byte = 32 KiB.

partitions
   (mandatory) A list of dictionaries. Each dictionary describes one
   partition.

The following key / value pairs can be given for each partition:

name
   (mandatory) The name of the partition.  With the help of this name,
   the partition can later be referenced, e.g. while creating a
   file system.

flags
   (optional) List of flags for the partition. Default: empty.
   Possible values:

   boot
      Sets the boot flag for the partition
   primary
      Partition should be a primary partition. If not set a logical
      partition will be created.

size
   (mandatory) The size of the partition.  The size can either be an
   absolute number using units like `10GiB` or `1.75TB` or relative
   (percentage) numbers: in the later case the size is calculated
   based on the remaining free space.

Example:

.. code-block:: yaml

   - partitioning:
      base: image0
      label: mbr
      partitions:
        - name: part-01
          flags: [ boot ]
          size: 1GiB
        - name: part-02
          size: 100%

  - partitioning:
      base: data_image
      label: mbr
      partitions:
        - name: data0
          size: 33%
        - name: data1
          size: 50%
        - name: data2
          size: 100%

On the `image0` two partitions are created.  The size of the first is
1GiB, the second uses the remaining free space.  On the `data_image`
three partitions are created: all are about 1/3 of the disk size.

Filesystem Caveat
-----------------

By default, disk-image-create uses a 4k byte-to-inode ratio when
creating the filesystem in the image. This allows large 'whole-system'
images to utilize several TB disks without exhausting inodes. In
contrast, when creating images intended for tenant instances, this
ratio consumes more disk space than an end-user would expect (e.g. a
50GB root disk has 47GB avail.). If the image is intended to run
within a tens to hundrededs of gigabyte disk, setting the
byte-to-inode ratio to the ext4 default of 16k will allow for more
usable space on the instance. The default can be overridden by passing
``--mkfs-options`` like this::

    disk-image-create --mkfs-options '-i 16384' <distro> vm

You can also select a different filesystem by setting the ``FS_TYPE``
environment variable.

Note ``--mkfs-options`` are options passed to the mfks *driver*,
rather than ``mkfs`` itself (i.e. after the initial `-t` argument).

Speedups
--------
If you have 4GB of available physical RAM (as reported by /proc/meminfo
MemTotal), or more, diskimage-builder will create a tmpfs mount to build the
image in. This will improve image build time by building it in RAM.
By default, the tmpfs file system uses 50% of the available RAM.
Therefore, the RAM should be at least the double of the minimum tmpfs
size required.
For larger images, when no sufficient amount of RAM is available, tmpfs
can be disabled completely by passing --no-tmpfs to disk-image-create.
ramdisk-image-create builds a regular image and then within that image
creates ramdisk.
If tmpfs is not used, you will need enough room in /tmp to store two
uncompressed cloud images. If tmpfs is used, you would still need /tmp space
for one uncompressed cloud image and about 20% of that image for working files.
