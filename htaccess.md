# Non-www to www Redirect
```bash
RewriteEngine On
RewriteCond %{HTTP_HOST} !^www\.
RewriteRule ^(.*)$ https://www.%{HTTP_HOST}/$1 [R=301,L]
```

# Set the Email Address for the Server Administrator
```bash
SetEnv SERVER_ADMIN default@example.com
```

# 301 redirects
```bash
Redirect 301 /oldpage.html https://www.yourwebsiteurl123.com/newpage.html
```

# Error handling
```bash
ErrorDocument 400 /errors/badrequest.html
ErrorDocument 401 /errors/authreqd.html
ErrorDocument 403 /errors/forbid.html
ErrorDocument 404 /errors/notfound.html
ErrorDocument 500 /errors/serverr.html
```

# Protect .htaccess File
```bash
# rename .htaccess files
AccessFileName ht.access

# protect renamed .htaccess files
<FilesMatch "^ht\.">
	Order deny,allow
	Deny from all
</FilesMatch>
```

# Limit server request methods to GET and PUT
```bash
Options -ExecCGI -Indexes -All
RewriteEngine on
RewriteCond %{REQUEST_METHOD} ^(TRACE|TRACK|OPTIONS|HEAD) RewriteRule .* - [F]
```

# Process files based on request method
```bash
Script PUT /cgi-bin/upload.cgi
Script GET /cgi-bin/download.cgi
```

# Prevent Access to a Files
```bash
# prevent viewing of a specific file
<files secretfile.jpg>
	Order allow,deny
	Deny from all
</files>

# prevent access to multiple file types
<FilesMatch "\.(htaccess|htpasswd|ini|phps|fla|psd|log|sh)$">
	Order Allow,Deny
	Deny from all
</FilesMatch>
```

# Directory Browsing
```bash
# disable directory browsing
Options All -Indexes

# enable directory browsing
Options All +Indexes

# prevent folder listing
IndexIgnore *

# prevent display of select file types
IndexIgnore *.wmv *.mp4 *.avi *.etc
```

# Allow or deny domain access for specified range of IP addresses
```bash
# block IP range by CIDR number
<Limit GET POST PUT>
	Order allow,deny
	Allow from all
	Deny from 99.88.77.66
  Deny from 99.88.77.*
	Deny from 80.0.0/8
  Deny from 99.88.77.66 11.22.33.44
  Deny from 99.1.0.0/255.255.0.0
  Deny from domain.com
</Limit>

# allow IP range by CIDR number
<Limit GET POST PUT>
	Order deny,allow
	Deny from all
	Allow from 10.1.0.0/16
	Allow from 80.0.0/8
  Allow from 99.*.*.*
  Allow from sub.domain.com
</Limit>
```

# Block Evil Robots, Site Rippers, and Offline Browsers
```bash
RewriteBase /
RewriteCond %{HTTP_USER_AGENT} ^Anarchie [OR]
RewriteCond %{HTTP_USER_AGENT} ^ASPSeek [OR]
RewriteCond %{HTTP_USER_AGENT} ^attach [OR]
RewriteCond %{HTTP_USER_AGENT} ^autoemailspider [OR]
RewriteCond %{HTTP_USER_AGENT} ^Xaldon\ WebSpider [OR]
RewriteCond %{HTTP_USER_AGENT} ^Xenu [OR]
RewriteCond %{HTTP_USER_AGENT} ^Zeus.*Webster [OR]
RewriteCond %{HTTP_USER_AGENT} ^Zeus
RewriteRule ^.* - [F,L]
```

# Password-protect Files, Directories
```bash
# password-protect single file
<Files secure.php>
	AuthType Basic
	AuthName "Prompt"
	AuthUserFile /home/path/.htpasswd
	Require valid-user
</Files>

# password-protect multiple files
<FilesMatch "^(execute|index|secure|insanity|biscuit)*$">
	AuthType basic
	AuthName "Development"
	AuthUserFile /home/path/.htpasswd
	Require valid-user
</FilesMatch>

# password-protect the directory in which this .htaccess rule resides
AuthType basic
AuthName "This directory is protected"
AuthUserFile /home/path/.htpasswd
AuthGroupFile /dev/null
Require valid-user

# password-protect directory for every IP except the one specified
# place in .htaccess file of a directory to protect that entire directory
AuthType Basic
AuthName "Personal"
AuthUserFile /home/path/.htpasswd
Require valid-user
Allow from 99.88.77.66
Satisfy Any
```

# Automatically CHMOD Various File Types
```bash
# ensure CHMOD settings for specified file types
# remember to never set CHMOD 777 unless you know what you are doing
# files requiring write access should use CHMOD 766 rather than 777
# keep specific file types private by setting their CHMOD to 400
chmod .htpasswd files 640
chmod .htaccess files 644
chmod php files 600
```

# Limit file upload size
```bash
LimitRequestBody 10240000
```

# Secure directories by disabling execution of scripts
```bash
AddHandler cgi-script .php .pl .py .jsp .asp .htm .shtml .sh .cgi
Options -ExecCGI
```

# Limit file upload size
```bash
LimitRequestBody 10240000
```
