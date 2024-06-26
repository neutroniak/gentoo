# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools linux-info pam udev

DESCRIPTION="Support for the UPEK/SGS Thomson fingerprint reader, common in Thinkpads"
HOMEPAGE="http://thinkfinger.sourceforge.net/"
SRC_URI="https://downloads.sourceforge.net/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug pam"

DEPEND="
	virtual/libusb:0
	pam? ( sys-libs/pam )"
RDEPEND="
	${DEPEND}
	acct-group/fingerprint"
BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}"/${PV}-direct_set_config_usb_hello.patch
	"${FILESDIR}"/${PV}-carriagereturn.patch
	"${FILESDIR}"/${PV}-send-sync-event.patch
	"${FILESDIR}"/${PV}-tftoolgroup.patch
	"${FILESDIR}"/${PV}-strip-strip.patch
	"${FILESDIR}"/${PV}-autoreconf.patch
	"${FILESDIR}"/${PV}-slibtool.patch
)

pkg_setup() {
	if use pam; then
		CONFIG_CHECK="~INPUT_UINPUT"
		ERROR_CFG="Your kernel needs uinput for the pam module to work"
		check_extra_config
	fi
}

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	econf \
		--disable-static \
		$(use_enable pam) \
		$(use_enable debug usb-debug) \
		--with-securedir="$(getpam_mod_dir)"

	rm README.in || die
}

src_install() {
	default

	keepdir /etc/pam_thinkfinger

	udev_dorules "${FILESDIR}"/60-thinkfinger.rules

	# no static archives
	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {
	udev_reload

	fowners root:fingerprint /etc/pam_thinkfinger
	fperms 710 /etc/pam_thinkfinger

	elog "Use tf-tool --acquire to take a finger print"
	elog "tf-tool will write the finger print file to /tmp/test.bir"
	elog

	if use pam; then
		elog "To add a fingerprint to PAM, use tf-tool --add-user USERNAME"
		elog
		elog "Add the following to /etc/pam.d/system-auth after pam_env.so"
		elog "auth     sufficient     pam_thinkfinger.so"
		elog
		elog "Your system-auth should look similar to:"
		elog "auth     required     pam_env.so"
		elog "auth     sufficient   pam_thinkfinger.so"
		elog "auth     sufficient   pam_unix.so try_first_pass likeauth nullok"
	fi
}
