# Structure of the dict

```
{
    "#chan1": {
        "user1": {
            "wallet": 000,
            "bets": {
                "color1": 000,
                "color2": 000,
                "odd": 000
            }
        },
        "user2": {
            "wallet": 000,
            "bets": {
                "color1": 000
            }
        }
    },
    "#chan2": {...}
}
```
chanX.userX.bets is erased after each turn, chanX.userX.wallet is increased/decreased in the same time