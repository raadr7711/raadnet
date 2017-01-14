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

# Changelog

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

## 0.7.7 - alpha (2017-01-01)

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