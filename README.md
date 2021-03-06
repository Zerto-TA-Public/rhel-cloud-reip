# RHEL-Cloud-Reip Scripts
- Written by: Zerto
- Updated by: Justin Paul jp@zerto.com

## Description:
This script is designed to help failover RHEL based machines into 
Azure or AWS.
It sets the network adatper to look for DHCP so that the public cloud 
can push the proper IP to the machine.
This script is meant for machines failing over from vCenter to Azure 
or AWS.

## Support info:
- RHEL Versions: 6.7,6.9, 7.0, 7.1, 7.2, 7.3 & 7.4
- Network settings:
- Static => DHCP
- DHCP => DHCP

## Installation:
This script is
1. Create a new folder: /tmp/reip
2. Download or git clone https://github.com/Zerto-TA-Public/rhel-cloud-reip then copy all the files to the /tmp/reip directory.
3. Run: cd /tmp/reip
4. Run: chmod +x ./reipinstaller.sh
5. Run: ./reipinstaller.sh

## Legal Disclaimer: 
All scripts are provided AS IS without warranty of any kind. 
The author and Zerto further disclaims all implied warranties including, 
without limitation, any implied warranties of merchantability or of 
fitness for a particular purpose. The entire risk arising out of the use 
or performance of the sample scripts and documentation remains with you. 
In no event shall Zerto, its authors, or anyone else involved in the 
creation, production, or delivery of the scripts be liable for any damages 
whatsoever (including, without limitation, damages for loss of business 
profits, business interruption, loss of business information, or other 
pecuniary loss) arising out of the use of or inability to use the sample 
scripts or documentation, even if the author or Zerto has been advised 
of the possibility of such damages.

