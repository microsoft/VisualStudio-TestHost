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

using System;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.Common;

namespace Microsoft.VisualStudioTools.VSTestHost.Internal {
    class TestProperties {
        private readonly ITestElement _testElement;
        private readonly Dictionary<string, string> _testSettings;

        public TestProperties(ITestElement testElement, TestRunConfiguration runConfig) {
            _testElement = testElement;
#if !VS11
            if (runConfig != null) {
                _testSettings = runConfig.TestSettingsProperties;
            }
#endif
        }

        public string this[string key] {
            get {
                string value;
                TryGetValue(key, out value);
                return value;
            }
        }

        public bool TryGetValue(string key, out string value) {
            value = null;
            if (_testElement != null && _testElement.Properties.ContainsKey(key)) {
                try {
                    value = (string)_testElement.Properties[key];
                    return true;
                } catch (KeyNotFoundException) {
                } catch (InvalidCastException) {
                }
            }
            if (_testSettings != null) {
                return _testSettings.TryGetValue(key, out value);
            }
            return false;
        }
    }
}
