# URL
Here is the [structure of a URL](https://en.wikipedia.org/wiki/URL):
![Image Structure](img/url-structure.png)

This regex stracts most elemnts of a URL including scheme, user, subdomain, domain, tld, path, query, and fragmentation. It still needs some improvements because the 3rd group (sibdomain, domain, tld) is not working perfectly.
```regex
(?i)(http[s]?:\/\/)?(?i)([0-9a-z-]*@)?(([0-9a-z-]+\.)*([0-9a-z-]{1,256})+(\.[0-9a-z-]{2,})+){1}(:\d*)*([\/|?]+[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)*
```
results can be found [here](https://regex101.com/r/BS07YR/2).
