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
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Threading;
using System.Windows.Forms;
using Microsoft.VisualStudioTools.VSTestHost.Internal;

namespace Microsoft.VisualStudioTools.VSTestHost {
    sealed class ScreenRecorder : IDisposable {
        private readonly System.Threading.Timer _timer;
        private readonly DirectoryInfo _output;
        private Bitmap _latestImage;
        private DateTime _latestImageTime;
        private TimeSpan _interval;
        private bool _isDisposed = false;

        public ScreenRecorder(string outputPath) {
            _timer = new System.Threading.Timer(Timer_Callback);
            _output = Directory.CreateDirectory(outputPath);
        }

        public void Dispose() {
            if (!_isDisposed) {
                _isDisposed = true;
                _timer.Dispose();

                var latestImage = _latestImage;
                _latestImage = null;
                if (latestImage != null) {
                    latestImage.Dispose();
                }
            }
        }

        public string Failure { get; private set; }

        public TimeSpan Interval {
            get {
                return _interval;
            }
            set {
                _interval = value;
                try {
                    _timer.Change((int)_interval.TotalMilliseconds, -1);
                } catch (ObjectDisposedException) {
                }
            }
        }

        private void Timer_Callback(object state) {
            if (_isDisposed) {
                return;
            }

            try {
                NextCapture();
            } catch (Exception ex) {
                if (ex is OutOfMemoryException || ex is ThreadAbortException || ex is AccessViolationException) {
                    throw;
                }
                Failure = ex.ToString();
            }
        }

        private void NextCapture() {
            var bmp = Capture(Screen.AllScreens);
            var time = DateTime.Now;

            var lastImage = _latestImage;
            if (!AreSame(lastImage, bmp)) {
                _latestImage = bmp;
                _latestImageTime = time;
                if (lastImage != null) {
                    lastImage.Dispose();
                }

                var nameFormat = time.ToString("s").Replace(":", "") + "{0}.png";
                using (var stream = OpenUniquelyNamedFile(_output.FullName, nameFormat)) {
                    bmp.Save(stream, ImageFormat.Png);
                }
            } else {
                bmp.Dispose();
            }

            try {
                _timer.Change((int)Interval.TotalMilliseconds, -1);
            } catch (ObjectDisposedException) {
            }
        }



        private static Stream OpenUniquelyNamedFile(string directory, string format) {
            string path = format;
            try {
                path = Path.Combine(directory, string.Format(format, ""));
                return new FileStream(
                    path,
                    FileMode.CreateNew,
                    FileAccess.Write,
                    FileShare.Read
                );
            } catch (IOException) {
            } catch (UnauthorizedAccessException) {
            } catch (NotSupportedException ex) {
                throw new NotSupportedException(path, ex);
            }

            // Try with an additional index
            for (int i = 0; i < 0x100; ++i) {
                try {
                    path = Path.Combine(directory, string.Format(format, string.Format("_{0}", i)));
                    return new FileStream(
                        path,
                        FileMode.CreateNew,
                        FileAccess.Write,
                        FileShare.Read
                    );
                } catch (IOException) {
                } catch (UnauthorizedAccessException) {
                } catch (NotSupportedException ex) {
                    throw new NotSupportedException(path, ex);
                }
            }

            // If we can't find an index, try a guid. If we still can't create
            // the file, let the exception out so the user hears about it.
            try {
                path = Path.Combine(directory, string.Format(format, string.Format("_{0:N}", Guid.NewGuid())));
                return new FileStream(
                    path,
                    FileMode.CreateNew,
                    FileAccess.Write,
                    FileShare.Read
                );
            } catch (NotSupportedException ex) {
                throw new NotSupportedException(path, ex);
            }
        }

        private static Bitmap Capture(IList<Screen> screens) {
            if (screens.Count == 0) {
                return null;
            }

            Rectangle bounds = GetScreensBounds(screens);

            var bmp = new Bitmap(bounds.Width, bounds.Height, PixelFormat.Format32bppArgb);
            try {
                using (var g = Graphics.FromImage(bmp)) {
                    g.Clear(Color.Black);
                    foreach (var s in screens) {
                        var d = s.Bounds.Location;
                        d.Offset(-bounds.X, -bounds.Y);
                        if (d.X < 0 || d.Y < 0) {
                            throw new InvalidOperationException(Resources.InvalidScreenBounds);
                        }
                        g.CopyFromScreen(s.Bounds.Location, d, s.Bounds.Size);
                    }
                }

                var res = bmp;
                bmp = null;
                return res;
            } finally {
                if (bmp != null) {
                    bmp.Dispose();
                }
            }
        }

        private static Rectangle GetScreensBounds(IList<Screen> screens) {
            var bounds = screens[0].Bounds;
            foreach (var s in screens.Skip(1)) {
                if (s.Bounds.X < bounds.X) {
                    bounds.X = s.Bounds.X;
                }
                if (s.Bounds.Y < bounds.Y) {
                    bounds.Y = s.Bounds.Y;
                }
                if (s.Bounds.Right > bounds.Right) {
                    bounds.Width = s.Bounds.Right - bounds.Left;
                    if (bounds.Right != s.Bounds.Right) {
                        throw new InvalidOperationException(Resources.InvalidScreenBounds);
                    }
                }
                if (s.Bounds.Bottom > bounds.Bottom) {
                    bounds.Height = s.Bounds.Bottom - bounds.Top;
                    if (bounds.Bottom != s.Bounds.Bottom) {
                        throw new InvalidOperationException(Resources.InvalidScreenBounds);
                    }
                }
            }

            return bounds;
        }

        private static unsafe bool AreSame(Bitmap x, Bitmap y) {
            if (x == null || y == null) {
                return x == null && y == null;
            }
            if (x.Width != y.Width || x.Height != y.Height) {
                return false;
            }

            var bounds = new Rectangle(Point.Empty, x.Size);
            BitmapData bdX = null, bdY = null;
            try {
                bdX = x.LockBits(bounds, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
                bdY = y.LockBits(bounds, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);

                var pX = (UInt32*)bdX.Scan0.ToPointer();
                var pY = (UInt32*)bdY.Scan0.ToPointer();
                int count = bdX.Width * bdX.Height;
                if (count != bdY.Width * bdY.Height) {
                    // Should have already returned earlier in this case
                    Debug.Fail("Bitmap sizes must match");
                    return false;
                }
                for (; count > 0; --count) {
                    if (*pX != *pY) {
                        return false;
                    }
                    pX += 1;
                    pY += 1;
                }

                return true;
            } finally {
                if (bdX != null) {
                    x.UnlockBits(bdX);
                }
                if (bdY != null) {
                    y.UnlockBits(bdY);
                }
            }
        }
    }
}
