# Changelog

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

## 0.7.7 [alpha] (2016-01-01)

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
* Logs
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