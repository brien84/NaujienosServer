# NaujienosServer
First, collects article links from various news websites' RSS feeds. Then parses the links to get missing data and keep it consistent through different news providers. Lastly, presents the data in JSON format.

Built with Server Side Swift [Vapor Framework](https://vapor.codes/).

# How to run the project
* Clone the repository
* Navigate into it and run `vapor build` ([make sure to install Vapor](https://docs.vapor.codes/3.0/install/macos/))
* To use Xcode, run `vapor xcode`
* To view the JSON data go to `localhost:8080/all`
