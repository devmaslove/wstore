## 1.0.0

* Initial release

## 1.0.1

* Fix: nested composed do not updated correctly
* Fix: computedConverter2 and subscribe2 do not work correctly with nullable value
* Important! Rename context.store to context.wstore
* Add to subscribe/subscribe2 future param

## 1.0.2

* Fix: computed values do not work correctly with nullable value

## 1.0.3

* Important! Remove from setStore names param, need call notifyChangeNamed after setStore if need
* Added GStore class and WStore.computedFromStore for organizing global storage
* Added WStoreStatus and WStoreStatusBuilder

## 1.0.4

* Added GStoreChangeObjectMixin

## 1.0.5

* fix computedFromStore - getValue function is called several times