# GitLab Automation

Gitlab installer for Ubuntu, Debian, CentOS, RHEL and OpenSUSE.

This script lets you set up your own Gitlab server in a couple of minutes, using your desired parameters. It is designed to be as user-friendly as possible, requiring minimum experience.

### Installation	

1. Download the installer script

```
curl -O https://raw.githubusercontent.com/Scriptease-Automation/gitlab/master/gitlab.sh
```

2. Make it executable

```
chmod +x gitlab.sh
```

3. Run the installer

```
bash ./gitlab.sh -d <your domain> 
```

### Additional options

```
-r <enabled/none> Enable/disable Container Registry
-n <registry domain> Set domain for Container Registry
```
