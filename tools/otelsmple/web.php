<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// manual span
use OpenTelemetry\API\Globals;
use Illuminate\Support\Facades\Log;
Route::get('/test', function () {
  function awesomeFunction(string $arg) {
    OpenTelemetry\API\Globals::registerInitializer(function (Configurator $configurator) {
		$propagator = TraceContextPropagator::getInstance();
		//$propagator = \OpenTelemetry\API\Baggage\Propagation\BaggagePropagator::getInstance();
        $spanProcessor = new BatchSpanProcessor(/*params*/);
        $tracerProvider = (new TracerProviderBuilder())
            ->addSpanProcessor($spanProcessor)
            ->setSampler(new ParentBased(new AlwaysOnSampler()))
            ->build();
    
        ShutdownHandler::register([$tracerProvider, 'shutdown']);
    
        return $configurator
            ->withTracerProvider($tracerProvider)
            ->withPropagator($propagator);
	});

    //$tracer = Globals::tracerProvider()->getTracer("smplapp-app");
    $tracer = Globals::tracerProvider()->getTracer("io.opentelemetry.contrib.php.laravel");
    $childSpan = $tracer->spanBuilder('wait20msTestSpan')->startSpan();
    $childSpan->setAttribute('arg', $arg);
    $scope = $childSpan->activate();

    try {
      // 計装対象の処理
      time_nanosleep(0, 20000000); // 20ms
	  Log::info("nano_slept.");
    } finally {
      $childSpan->end();
      $scope->detach();
    }
  }
  awesomeFunction('testarg:abc-def');
  return phpinfo();
  //return view('test');
});

