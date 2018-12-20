// Visual Studio Test Host
// Copyright(c) Microsoft Corporation
// All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the License); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0
//
// THIS CODE IS PROVIDED ON AN  *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY
// IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
// MERCHANTABLITY OR NON-INFRINGEMENT.
//
// See the Apache Version 2.0 License for specific language governing
// permissions and limitations under the License.

using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

// The following assembly information is common to all VisualStudioTools Test assemblies.
// If you get compiler errors CS0579, "Duplicate '<attributename>' attribute", check your 
// Properties\AssemblyInfo.cs file and remove any lines duplicating the ones below.
[assembly: AssemblyCompany("Microsoft")]
[assembly: AssemblyProduct("VSTestUtilities")]
[assembly: AssemblyCopyright("Copyright © Microsoft 2018")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]
[assembly: AssemblyVersion(AssemblyVersionInfo.StableVersion)]
[assembly: AssemblyFileVersion(AssemblyVersionInfo.Version)]

class AssemblyVersionInfo {
    // This version string (and the comments for StableVersion and Version)
    // should be updated manually between major releases.
    // Servicing branches should retain the value
    public const string ReleaseVersion = "1.0";
    // This version string (and the comment for StableVersion) should be
    // updated manually between minor releases.
    // Servicing branches should retain the value
    public const string MinorVersion = "0";

    public const string BuildNumber = "0.00";

#if DEV10
    public const string VSMajorVersion = "10";
    const string VSVersionSuffix = "2010";
#elif DEV11
    public const string VSMajorVersion = "11";
    const string VSVersionSuffix = "2012";
#elif DEV12
    public const string VSMajorVersion = "12";
    const string VSVersionSuffix = "2013";
#elif DEV14
    public const string VSMajorVersion = "14";
    const string VSVersionSuffix = "2015";
#elif DEV15
    public const string VSMajorVersion = "15";
    const string VSVersionSuffix = "15";
#elif DEV16
    public const string VSMajorVersion = "16";
    const string VSVersionSuffix = "16";
#else
#error Unrecognized VS Version.
#endif

    public const string VSVersion = VSMajorVersion + ".0";

    // Defaults to "1.0.0.(2010|2012|2013|2015)"
    public const string StableVersion = ReleaseVersion + "." + MinorVersion + "." + VSVersionSuffix;

    // Defaults to "1.0.0.00"
    public const string Version = ReleaseVersion + "." + BuildNumber;
}
