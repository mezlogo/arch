#!/bin/bash
useradd -m -G wheel -s /bin/bash mezlogo

passwd mezlogo

if ! grep '^%wheel' /etc/sudoers ; then echo '%wheel      ALL=(ALL) ALL' >> /etc/sudoers ; fi