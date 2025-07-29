"""The asyncio package, tracking PEP 3156."""

# flake8: noqa

import sys

# This relies on each of the submodules having an __all__ variable.
from . import base_events
from .base_events import *

from . import coroutines
from .coroutines import *

from . import events
from .events import *

from . import exceptions
from .exceptions import *

from . import futures
from .futures import *

from . import locks
from .locks import *

from . import protocols
from .protocols import *

from . import runners
from .runners import *

from . import queues
from .queues import *

from . import streams
from .streams import *

from . import subprocess
from .subprocess import *

from . import tasks
from .tasks import *

from . import taskgroups
from .taskgroups import *

from . import timeouts
from .timeouts import *

from . import threads
from .threads import *

from . import transports
from .transports import *

__all__ = (base_events.__all__ +
           coroutines.__all__ +
           events.__all__ +
           exceptions.__all__ +
           futures.__all__ +
           locks.__all__ +
           protocols.__all__ +
           runners.__all__ +
           queues.__all__ +
           streams.__all__ +
           subprocess.__all__ +
           tasks.__all__ +
           threads.__all__ +
           timeouts.__all__ +
           transports.__all__)

if sys.platform == 'win32':  # pragma: no cover
    from .windows_events import *
    __all__ += windows_events.__all__
elif sys.platform in ['emscripten','wasi']:
    from .wasm_events import *
    __all__ += wasm_events.__all__
else:
    from .unix_events import *  # pragma: no cover
    __all__ += unix_events.__all__

def __getattr__(name: str):
    import warnings

    match name:
        case "AbstractEventLoopPolicy":
            warnings._deprecated(f"asyncio.{name}", remove=(3, 16))
            return events._AbstractEventLoopPolicy
        case "DefaultEventLoopPolicy":
            warnings._deprecated(f"asyncio.{name}", remove=(3, 16))
            if sys.platform in ['emscripten','wasi']:
                return wasm_events._DefaultEventLoopPolicy
            elif sys.platform == 'win32':
                return windows_events._DefaultEventLoopPolicy
            return unix_events._DefaultEventLoopPolicy
        case "WindowsSelectorEventLoopPolicy":
            if sys.platform == 'win32':
                warnings._deprecated(f"asyncio.{name}", remove=(3, 16))
                return windows_events._WindowsSelectorEventLoopPolicy
            # Else fall through to the AttributeError below.
        case "WindowsProactorEventLoopPolicy":
            if sys.platform == 'win32':
                warnings._deprecated(f"asyncio.{name}", remove=(3, 16))
                return windows_events._WindowsProactorEventLoopPolicy
            # Else fall through to the AttributeError below.

    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")

