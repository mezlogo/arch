#!/bin/bash
useradd -m -G wheel -s /bin/bash ${$1:?not null}

passwd ${$1:?not null}

if ! grep '^%wheel' /etc/sudoers ; then echo '%wheel      ALL=(ALL) ALL' >> /etc/sudoers ; fi
