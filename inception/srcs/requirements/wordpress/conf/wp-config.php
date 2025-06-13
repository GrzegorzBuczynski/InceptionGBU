<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * Localized language
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** Database username */
define( 'DB_USER', 'mysql_user' );

/** Database password */
define( 'DB_PASSWORD', 'mysql_pass' );

/** Database hostname */
define( 'DB_HOST', 'mariadb' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',          'h@zxv18Ed,nCB#v_@U;k0$^A./vI9uXcjAGN2J9&h!;v@196O]B!.uqZm]0_TIMO' );
define( 'SECURE_AUTH_KEY',   '[INDyRpb^u(#s`+Wn5J 9kcROsE7%Ohfs3a~k~nlvk!P6^@,_sPe4T7j()8L^7{g' );
define( 'LOGGED_IN_KEY',     'X6C:_)rX#yr*cidPKR/X$<}cN(d0M{Pzs@Q(]?4{]SWbf )9&8-96dN(e;{C.<%>' );
define( 'NONCE_KEY',         'Yysn`m0_]@T6KM=H,oZV]ODk$3{RE0.GXdmR}!@QP)5MOK{]D6p?9^-kNy^:ZnBb' );
define( 'AUTH_SALT',         '# n?E|;oMNKZ)tG]vgD*&P`t]dN4n@xxK21X/mM0[aCS3hl=uFkJ[v@u1v$yN%/R' );
define( 'SECURE_AUTH_SALT',  '|F-Xiw~Gv6RM?6x4c1>O e;=ed#5yS2*G/BWL2Wg)/bDd:.c6},#oM7;wswA[&vv' );
define( 'LOGGED_IN_SALT',    '~$P]R$<T7OnW/0!QXun2,k_n/Dp Y,]x&yHgt/e@PxF24,9_l95F3ANTzBG,,.Uq' );
define( 'NONCE_SALT',        ':SdJL3bj3b?ivd]kdL=MVhiN9Fw[Wa>0G&hxbb2@NQkEE}jr:A FTvu @s3x@^;x' );
define( 'WP_CACHE_KEY_SALT', 'LV#&JVlb^n/4d:u7@<2Q&.9HW9b.^omW?#dP`6ZZev8q.Oa96zjLds@XPfc>++Q.' );


/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';


/* Add any custom values between this line and the "stop editing" line. */



/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
if ( ! defined( 'WP_DEBUG' ) ) {
        define( 'WP_DEBUG', false );
}
        if (isset($_SERVER['HTTP_HOST'])) {
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https://' : 'http://';
        define('WP_HOME', $protocol . $_SERVER['HTTP_HOST']);
        define('WP_SITEURL', $protocol . $_SERVER['HTTP_HOST']);
        }

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
        define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
error_log('HTTP_HOST: ' . $_SERVER['HTTP_HOST']);