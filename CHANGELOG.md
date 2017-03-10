# Changelog

## 0.7.13 (TBD)

### Added
* **Add discovery manager v1 (supports local networks).**
* Add FW upgrade to minimal supported FW in discovery manager.
* Add CSV import to discovery manager.
* Add default IP range to discovery manager.
* Add GMAIL and generic SMTP account validation in the settings and in the wizard.
* Add badge with count of unauthorized devices to left menu.
* Add statistics for switch ports.
* Add ONU distance to ONU list.

### Changed
* Update internal data transformation (preparation for new device types).
* Update platform check in the installation script.
* Hide link to unms.ubnt.com until it's publicly available.
* Stop all docker containers in correct order before redeploying.
* Add support for self signed smtp servers.
* Delay downloading of device configuration after any change.
* Finish PPPoE interface editor.
* Finish VLAN interface editor.
* Remove ONUs when deleting OLT form UNMS.
* Store ONU distance, CPU, RAM, voltage
* Installation script offers alternative ports when default ports are occupied.
* Propagate configuration errors from devices to UNMS UI.
* Update interface name. It is showed as description (name).

### Fixed
* **Fix stability of devices connection (FW 1.9.6alpha2).**
* Fix site and endpoint status update.
* Fix refresh interfaces UI.
* Fix upload of huge images.
* Fix correct startup order of FW containers.
* Fix downloads in Firefox.
* Fix renaming DHCP servers
* Fix DHCP leases validation.
* Fix docker volume permissions.
* Fix installation with self signed certificate.
* Fix outage duration time.
* Fix UNMS port in connections string.
* Fix duplicated labels in statistics.
* Fix computing values for day and month statistics

## 0.7.12 (2017-02-12)

### Added
* Add new sections to UNMS installation wiki page (new advanced features such as custom ports mapping and custom ssl certificate) 
* Add note field to device move popup
* Add POE confirm dialog
* Add support for fullscreen maps
* Add image reordering and drag & drop support
* Add drag & drop upload to galleries
* Add interface editors for OLTs
* Add loglines when device reappear in UNMS
* [Add loglines for failed login](https://github.com/Ubiquiti-App/UNMS/issues/18)
* [Add clickable device name in logline popup](https://github.com/Ubiquiti-App/UNMS/issues/20)
* [Add loglines about who moves devices / approves authorizations](https://github.com/Ubiquiti-App/UNMS/issues/19)
* Add loglines for interface status changes
* Add mock version of Discovery manager
* Add mass device configuration backup download
* Add auto device configuration backup when device connect to UNMS
* Add link between ONUs in ONU list to ONU editor
* Add SMTP help to installation wizard
* Add device and site links to loglines
* Add new loglines about data migration (UNMS version upgrade)

### Changed
* **Migrate UNMS from MongoDB to PostgreSQL** 
* Installation script checks docker-compose (upgrade is supported)
* Installation script can setup custom HTTP and HTTPS ports
* Installation script allow to setup custom SSL certificate
* Address is optional for sites and endpoints
* Update device configuration backup file names
* Icons in all sections show device/site/endpoints status
* Remove switch disable action
* Update help in the new version notification popup
* Remove loglines older than one month
* Remove outages older than three months

### Fixed
* Fix SFP and PON port editor
* Fix search devices by model and version
* Fix bug with UNMS connection string
* Fix backend for DHCP servers and leases 
* Fix sites and endpoints status
* Fix SMTP setup
* Fix ERPoe5 icons and port configuration
* Fix certificate renewal
* Fix switch ports backend
* Fix gallery UI bugs
* Fix CIDR addresses validations and editors
* Fix synchronization of interfaces state
* Fix logline counts in logline popup
* Fix rendering device uptime (longer than one month)
* Fix rendering device router screen header

## 0.7.11 (2017-01-20)

### Added
* [Display Optical Vender Name](https://github.com/Ubiquiti-App/UNMS/issues/15)
* Support for EdgePoints (EP-R6, EP-R8)
* New screen list of all ONUs for OLT
* Icons for all devices

### Changed
* Change UNMS default page to devices
* Change favicon to UBNT logo

### Fixed
* Fix outages for deleted devices
* Fix outages during UNMS restart
* Fix input autocomplete behaviour
* Fix services screen for disconnected devices
* Fix logs rendering
* Fix ONU signal rendering
* Fix scroll in Firefox
* Fix rendering images in gallery
* Fix icons rendering in maps
* Fix screen blinking during data load
* Fix minor UI bugs and stability

## 0.7.10 (2017-01-12)

### Added
* Add notifications about the new UNMS version
* New log events for devices: authorization, delete, restart, backups, discover, move.
* New screen device settings for OLT
* New screen device services for OLT
* List of all DHCP leases
* IP addresses in device interfaces are clickable

### Changed
* [Responsive header](https://github.com/Ubiquiti-App/UNMS/issues/13)
* Responsive services page
* Isolate backend services in docker compose
* UNMS support info includes full server log
* Optimise notification mailing
* Disable setup route on configured UNMS 
* Refactor error messages and validation rules

### Fixed
* [Fix device configuration backup](https://github.com/Ubiquiti-App/UNMS/issues/5)
* Fix tx rate and rx rate in statistics
* Fix DNS servers validation
* Fix NTP servers validation
* Fix assigning device to the newly created site
* Fix outages without site
* Fix outages popover (rendering and data)
* Fix unread logs counter
* Fix links to devices under Logs and Outages

## 0.7.9 (2017-01-05)

### Added
* [Add help for latency/outage](https://github.com/Ubiquiti-App/UNMS/issues/8)
* EdgeRouter DHCP server list
* EdgeRouter DHCP server block/unblock actions
* Help with basic tutorials

### Changed
* [Self include Google fonts](https://github.com/Ubiquiti-App/UNMS/issues/4)
* [Remove random vertical line on graphs](https://github.com/Ubiquiti-App/UNMS/issues/7)
* Disable settings for disconnected devices
* Update backend to Node.js 7.3
* Lock UNMS during backup and restore

### Fixed
* [Fixed gmail SMTP Settings Failure](https://github.com/Ubiquiti-App/UNMS/issues/10)
* [Standardized Naming Scheme UNMS or Edge Control](https://github.com/Ubiquiti-App/UNMS/issues/9)
* Fixed incorrect ONU state after reconnect ONU from one OLT to other
* Fixed devices up-time and devices outage period format

## 0.7.7 (2017-01-01)

### Configuration
* Installation wizard
* Users administration
* Application backup and restore
* Google map, SMTP and devices check configuration
* Users preferences
* Demo and presentation mode

### EdgeRouter
* List of all interfaces with interface configuration
* Services configuration (NTP, SSH, Telnet, Syslog, SNMP, Web, Discovery)
* Logs list with filtering
* Statistics (latency, outage, cpu, memory, download/upload for all interfaces/ports) with hour/day/month view.
* Device configuration backup
* Device basic settings (name, timezone, gateway, DNS, users)

### OLT
* List of all Ports
* Logs list with filtering
* Statistics (latency, outage, cpu, memory, download/upload for all interfaces/ports) with hour/day/month view.
* Device configuration backup

### ONU
* Logs list with filtering
* Statistics (latency, outage, cpu, memory, download/upload for all interfaces/ports) with hour/day/month view.

### Sites
* Sites list with filtering
* Sites map
* Sites editor with alerts support
* Endpoints list
* Devices list
* Logs list with filtering
* Gallery

### Endpoints
* Endpoints list with filtering
* Endpoints map
* Endpoints editor with alerts support
* Devices list
* Logs list with filtering
* Gallery

### Devices
* Devices list with filtering
* There are following actions for each device: authorize, move, delete and restart

### Logs
* Logs list with filtering
* UNMS logs: user login, cpu/mem problems, device disconnection

### Outages
* List of all outages

# Versioning
* 0.7.x - Alpha
* 0.8.x - Beta
* 0.9.x - Release Candidate
* 1.0.x - Production Release

# Planned key features for 1.0.0
* **EdgeRouter** - Routing editor
* **EdgeRouter** - QoS editor
* **EdgeRouter** - Firewall editor
* **EdgeSwitch** - Full support
* **UNMS** - Full-text search
* **UNMS** - Network dashboard
* **UNMS** - Devices discovery manager
* **UNMS** - Firmwares upgrade manager
* **UNMS** - Application automatic upgrade
* **UNMS** - SSO support for UBNT account
* **UNMS** - Remote device CLI in UNMS UI
