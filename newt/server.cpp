#include "http_server.hpp"

using HttpServer = SimpleWeb::Server<SimpleWeb::HTTP>;

HttpServer& start (std::string address, unsigned short port) {
    HttpServer  *server = new HttpServer(address, port);
    server->start();
    return *server;
}

void add_endpoint(HttpServer* server, std::string res_name, std::string res_method,
      std::function<
          void(std::shared_ptr<typename SimpleWeb::ServerBase<SimpleWeb::HTTP>::Response>,
               std::shared_ptr<typename SimpleWeb::ServerBase<SimpleWeb::HTTP>::Request>)>
          res_fn){
    server->add_endpoint(res_name, res_method, res_fn);
}

int main () {
    /*
    HttpServer server(address, port);
    server.start();
    */
    return 0;
}

// g++ -std=c++11 -DBOOST_SYSTEM_NO_DEPRECATED  http_server.hpp server.cpp -o fuck.out -lboost_system -lpthread