/* ****************************************************************************
 *
 * Copyright (c) Microsoft Corporation. 
 *
 * This source code is subject to terms and conditions of the Apache License, Version 2.0. A 
 * copy of the license can be found in the License.html file at the root of this distribution. If 
 * you cannot locate the Apache License, Version 2.0, please send an email to 
 * vspython@microsoft.com. By using this source code in any fashion, you are agreeing to be bound 
 * by the terms of the Apache License, Version 2.0.
 *
 * You must not remove this notice, or any other, from this software.
 *
 * ***************************************************************************/

namespace Microsoft.VisualStudioTools.VSTestHost {
    public static class VSTestProperties {
        public static class ScreenCapture {
            public const string Key = "ScreenCapture";
            public const string IntervalKey = "ScreenCaptureInterval";
        }

        public static class VSApplication {
            public const string Key = "VSApplication";
            public const string VisualStudio = "VisualStudio";
            public const string WDExpress = "WDExpress";
            public const string VWDExpress = "VWDExpress";
            public const string Mock = "Mock";
        }

        public static class VSExecutable {
            public const string Key = "VSExecutable";
            public const string DevEnv = "devenv";
            public const string WDExpress = "wdexpress";
            public const string VWDExpress = "vwdexpress";
        }

        public static class VSVersion {
            public const string Key = "VSVersion";
        }

        public static class VSHive {
            public const string Key = "VSHive";
            public const string Exp = "Exp";
        }

        public static class VSLaunchTimeoutInSeconds {
            public const string Key = "VSLaunchTimeoutInSeconds";
        }

        public static class VSDebugMixedMode {
            public const string Key = "VSDebugMixedMode";
        }

        public static class VSReuseInstance {
            public const string Key = "VSReuseInstance";
        }
    }
}
