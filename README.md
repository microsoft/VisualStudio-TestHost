# VisualStudio-TestHost

[![Join the chat at https://gitter.im/Microsoft/VisualStudio-TestHost](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Microsoft/VisualStudio-TestHost?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Infrastructure for executing interactive UI tests in Visual Studio.

## Quick Start

The latest [release](https://github.com/Microsoft/VisualStudio-TestHost/releases) will install the required components into all supported versions of Visual Studio. After installing a new version of Visual Studio, you will need to reinstall the test host.

Test settings files are used to specify the version of Visual Studio to launch. [Example file](https://github.com/Microsoft/PTVS/blob/master/Build/default.14.0Exp.testsettings)

Add the `[HostType("VSTestHost")]` attribute to your unit tests, and your test will now launch VS and run within its process. The VS instance will be reused between tests, so make sure you clean everything up regardless of whether your test passes or fails. In [PTVS](https://github.com/Microsoft/PTVS) we use a [helper class](https://github.com/Microsoft/PTVS/blob/master/Common/Tests/Utilities.UI/UI/VisualStudioApp.cs) with `IDisposable` to ensure that failed tests do not affect later ones.

Use the `VSTestContext` static class to access the global service provider and DTE objects of the running Visual Studio instance. You can obtain a UI automation object with `AutomationElement.FromHandle(VSTestContext.DTE.MainWindow.HWnd)`.

For information about how this extension works, see the [Developer Guide](DeveloperGuide.md).

## Supported Versions

The following versions of Visual Studio may be used as test *targets*:

* Visual Studio 2015 Community and higher
* Visual Studio Express 2015 for Web or Desktop
* Visual Studio 2013 Community and higher
* Visual Studio Express 2013 for Web or Desktop with Update 2
* Visual Studio 2012 Professional and higher

The following versions of Visual Studio may be used to *launch* tests:

* Visual Studio 2015 Community and higher
* Visual Studio 2013 Community and higher

(The difference in support is due to changes in the unit test framework. If possible, tests should be launched with the same version as the test target.)

## Test Settings

These settings should be specified in a `.testsettings` file or with the `TestProperty` attribute before launching tests.

| Setting | Description | Values |
| --- | --- | --- |
| VSApplication | The registry key name | "VisualStudio", "WDExpress", "VWDExpress", "Mock" |
| VSExecutable  | The executable name | "devenv", "wdexpress", "vwdexpress" |
| VSVersion     | The version number | "11.0", "12.0", "14.0" or blank (match tester) |
| VSHive | The hive name | "Exp" or blank |
| VSLaunchTimeoutInSeconds | The number of seconds to wait for launch | Any number, or blank (30s) |
| VSDebugMixedMode | Use native debugging for tests | "True", "False" or blank |
| ScreenCapture | Directory to capture screenshots into | Blank (do not capture) or a relative path |
| ScreenCaptureInterval | Milliseconds between screenshots | Any number, or blank (1000ms) |

If `VSApplication` is set to `Mock`, no instance of Visual Studio will be launched and tests will be run in the current process. In this case, the `VSTestContext.IsMock` property will be `true` and `VSTestContext.ServiceProvider` should be set by your test run initializer.

When screen capture is enabled, only unique screenshots are retained, and all screenshots are deleted when a test passes.
