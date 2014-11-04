Setting up PostgreSQL
=====================


# Login to Azure

- Download publish settings at https://manage.windowsazure.com/publishsettings/index?client=xplat 

```
npm install azure-cli
azure account import "Windows Azure MSDN - Visual Studio Ultimate-11-4-2014-credentials.publishsettings"
azure account set "internal"
azure account list
```


# See what's going on

```
azure vm list --json

```



