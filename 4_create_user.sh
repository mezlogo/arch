#!/bin/bash
useradd -m -G wheel -s /bin/bash ${USERNAME:?not null}

passwd ${USERNAME:?not null}

if ! grep '^%wheel' /etc/sudoers ; then echo '%wheel      ALL=(ALL) ALL' >> /etc/sudoers ; fi
