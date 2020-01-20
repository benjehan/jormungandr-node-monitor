## MY PRETTY MONITORING SCRIPT WITH LOGGING

Thanks to [bobdobs](https://github.com/bobdobs/cardano-scripts) for making this script. I've taken his work and added my own something-something to it to make it work "better" and look "prettier".

### STEP 1: INSTALL PREREQUISITS 

In order to check for forked blocks we need to use SQlite to query the block database created by Jormungandr. So here is how to install SQLite3:

```sudo apt install sqlite3```


### STEP 2: PUT JORMUNGANDR IN YOUR PATH

You need to put Jormungandr into your path so you can just type "jormungandr" anywhere to run it. To do that you need to edit your **.profile** file in your home directory.

`export PATH=$PATH:/path/to/jormungandr:/path/to/jcli`

### STEP 3: SETUP JORMUNGANDR SERVICE

First you need to setup Jormungandr to run as a service. You want to do this because if your node becomes unresponsive, using the JCLI to connect and shutdown the node is not going to work. You won't be able to reset your node.

If your system uses **systemctl** to start and stop services, then you'll need to edit the file: 

```/etc/systemd/system/jorg.service``` 

Yyou will want to create the file jorg.service, it doesn't exist. And we're calling it 'jorg' because its easy to remember and quick to type (service jorg start|stop|restart).

```
[Unit]
Description=Jormungandr
After=multi-user.target

[Service]
Type=simple
ExecStart=jormungandr --config /path/to/config-file --genesis-block-hash replacethiswithgenesisblockhash --secret /path/to/node-secret-key

LimitNOFILE=16384

Restart=on-failure
RestartSec=5s
User=YOURUSERNAME
Group=YOURUSERSGROUP

[Install]
WantedBy=multi-user.target
```

Once thats done you need to reload the changes: **systemctl daemon-reload && systemctl enable jorg && systemctl start jorg**

### STEP 4: RUN THE JORG SERVICE AS SUDO WITHOUT A PASSWORD

Since Jormungandr (jorg) is a service you need to be sudo to run it and its going to totally ruin your day to come back to your server only to see the monitor is stuck asking for a password to reset jorg. So here is what you need to do, if your user is not already in the sudo group, as root do this: **usermod -aG sudo USERNAME**

Next, youll need to do: 

```sudo visudo -f /etc/sudoers.d/YOURUSERNAME```

This is going to create a file that contains your overrides for the sudo command. In the editor thats opened with the above command put this: 

```YOURUSERNAME ALL = (root) NOPASSWD: /usr/sbin/service```

This will allow you to run the service command without asking for a password. This is only going to let you use that one command without a password, nothing else. 

### STEP 5: MONITORING & LOGGING

Copy the script to /bin or somewhere in your path. The script outputs to the screen and runs in a loop. It also outputs the same info to a log file so you can review it later. You will want to edit the **${LOG_FILE}** variable to set where to store your logs. The script will run until you stop it.

**THE FIRST LINE OF OUTPUT WHEN THE START THE SCRIPT IS GARBAGE, IGNORE IT. PAY NO ATTENTION TO IT. MOVE ALONG TO LINE TWO.**

Here is a sample of the output: 

```
DATE: Today's date
EP: Epoch
SLOT: Current Slot
EXP. TIME: Last Block Time @ Shelley Explorer
LOCAL TIME: Last Block Time @ localhost
DIFFS: Time difference between shelley explorer getting the block and when your node got the block
HEIGHT: Local Chain Height
SHLXPR: Shelley Chain Height
POOLTL: Consensus Chain Height @ Pooltool.io
BX: Blocks behind Shelley Explorer
BP: Blocks Behind PoolTool.io consensus tip
HASH: Last Block Hash
FORK: Possible fork on this block (number of blocks created)
COUNT: Events since last reset (not shown for space reasons)

"------" or "--" means there are no differences or changes the values is equal to zero.

===DATE===      EP   SLOT      EXP. TIME      LOCAL TIME     DIFFS     HEIGHT    SHLXPR    POOLTL    BX   BP   HASH     FORK
2020-01-20      37   41426     18:14:29       18:14:29       ------    115781    115781    115780    0    -1   8b941     000 
2020-01-20      37   41437     18:14:51       18:14:51       ------    115782    115782    115780    0    -2   3f593     000 
2020-01-20      37   41444     18:15:05       18:15:05       ------    115783    115783    115782    0    -1   4636c     000  2020-01-20      37   41461     18:15:39       18:15:39       ------    115785    ------    115782    --   -3   88924     000 
2020-01-20      37   41473     18:16:03       18:16:03       ------    115787    115786    115782    -1   -5   4f2fb     000  2020-01-20      37   41481     18:16:19       18:16:20       -1s       115788    115788    115786    0    -2   9fefa     000 
2020-01-20      37   41497     18:16:51       18:16:51       ------    115789    115789    115786    0    -3   33208     000 
2020-01-20      37   41524     18:17:45       18:17:45       ------    115790    115790    115789    0    -1   89045     000 
2020-01-20      37   41533     18:18:03       18:18:03       ------    115792    115792    115790    0    -2   de68f     000 2020-01-20      37   41550     18:18:37       18:18:38       -1s       115793    115793    115790    0    -3   ec54a     000  2020-01-20      37   41557     18:18:51       18:18:51       ------    115794    115794    115794    0    0    a72b1     000      

```
