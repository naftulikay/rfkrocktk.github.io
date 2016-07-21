---
layout: post
title: MacBook Pro 11,4 and 11,5 Patch for Suspend Bug
tags: macbook, linux, hardware, suspend
---

There's a [nasty little Linux kernel bug][bugzilla-report] affecting MacBook Pro 11,4 and 11,5 models that makes it
impossible to suspend and resume (and even power off) on this hardware. Luckily, a kernel developer has fixed the issue,
though it hasn't been merged to mainline yet. Here's how to apply and compile the patch for Ubuntu Trusty and later on
the LTS Xenial kernel. The patch is also applicable for other distributions and kernel versions, though it might
not directly apply.

Follow the [Ubuntu Kernel Compiling Guide][ubuntu-kernel-build], but before you build the kernel, apply the following
patch, also available [as a Gist][gist-patch]:

```
diff --git a/drivers/pci/quirks.c b/drivers/pci/quirks.c
index 1595f4f..b577af2 100644
--- a/drivers/pci/quirks.c
+++ b/drivers/pci/quirks.c
@@ -2749,6 +2749,13 @@ static void quirk_hotplug_bridge(struct pci_dev *dev)

 DECLARE_PCI_FIXUP_HEADER(PCI_VENDOR_ID_HINT, 0x0020, quirk_hotplug_bridge);

+static void quirk_hotplug_bridge_skip(struct pci_dev *dev)
+{
+	dev->is_hotplug_bridge = 0;
+}
+
+DECLARE_PCI_FIXUP_HEADER(PCI_VENDOR_ID_INTEL, 0x8c10, quirk_hotplug_bridge_skip);
+
 /*
  * This is a quirk for the Ricoh MMC controller found as a part of
  * some mulifunction chips.

```

On the [Gist's page][gist-patch], a PGP signature is also available. Alternatively, you can find the patch on the
[kernel's bug report page at comment #172][bugzilla-report-comment].

After building and installing the kernel, make sure to use your package manager's hold feature to prevent updates to
the package to prevent suspend from being broken by an update or from having your distribution replace your custom
kernel with the unpatched upstream version. It would also be wise to check periodically for new security patches on your
distribution and recompile as necessary to get kernel patches.

 [bugzilla-report]: https://bugzilla.kernel.org/show_bug.cgi?id=103211
 [bugzilla-report-comment]: https://bugzilla.kernel.org/show_bug.cgi?id=103211#c172
 [ubuntu-kernel-build]: https://wiki.ubuntu.com/Kernel/BuildYourOwnKernel
 [gist-patch]: https://gist.github.com/rfkrocktk/2226b0c78f61eb8495924fcd36c123a2
